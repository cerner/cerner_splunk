# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: splunk_app.rb
#
# Libraries for managing custom apps.

require 'chef/provider'
require 'chef/resource'

module CernerSplunk
  # Utilities to use with the splunk_app resource/provider
  class SplunkApp
    def self.merge_hashes(*hashes)
      hashes.collect(&:keys).flatten.uniq.each_with_object({}) do |app_name, result|
        app_hash = {}

        merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }

        hashes.each do |hash|
          to_merge = hash[app_name]
          next unless to_merge.is_a? Hash
          app_hash.merge!(to_merge, &merger)
        end

        result[app_name] = app_hash unless app_hash.empty?
      end
    end
  end
end

class Chef
  class Resource
    # Chef Resource for managing Splunk apps
    class SplunkApp < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :splunk_app
        @action = :create
        @allowed_actions = [:create, :remove]
        @local = false
        @permissions = {}
        @files = {}
        @app = name
      end

      def apps_dir(arg = nil)
        set_or_return(:apps_dir, arg, kind_of: String, required: true)
      end

      def local(arg = nil)
        val = set_or_return(:local, arg, kind_of: [TrueClass, FalseClass])
        (url.nil? || url.empty?) ? val : true
      end

      def files(arg = nil)
        set_or_return(:files, arg, kind_of: Hash)
      end

      def permissions(arg = nil)
        set_or_return(:permissions, arg, kind_of: Hash)
      end

      def app(arg = nil)
        set_or_return(:app, arg, kind_of: String)
      end

      # Calculated attributes
      def required_directories
        %w(local default metadata lookups).collect { |d| "#{root_dir}/#{d}" }.unshift(root_dir)
      end

      def root_dir
        "#{apps_dir}/#{app}"
      end

      def default_dir
        "#{root_dir}/default"
      end

      def files_dir
        local ? "#{root_dir}/local" : default_dir
      end

      def perms_file
        file_name = local ? 'local.meta' : 'default.meta'
        "#{root_dir}/metadata/#{file_name}"
      end
    end
  end
end

class Chef
  class Provider
    # Chef Provider for managing Splunk apps
    class SplunkApp < Chef::Provider
      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource ||= Chef::Resource::SplunkApp.new(new_resource.name)
        @current_resource.apps_dir(new_resource.apps_dir)
        @current_resource.local(new_resource.local)
        @current_resource.app(new_resource.app)
        @current_resource.permissions(CernerSplunk::Conf::Reader.new(new_resource.perms_file).read)

        app_conf = CernerSplunk::Conf::Reader.new("#{new_resource.default_dir}/app.conf").read
        @current_resource.version((app_conf['launcher'] || {})['version'])
      end

      def action_create
        create_app_directories
        manage_metaconf unless new_resource.permissions.empty?
        new_resource.files.each do |file_name, contents|
          *directories, file_name = file_name.split('/')
          file_path = new_resource.files_dir
          directories.each do |subdir|
            file_path = "#{file_path}/#{subdir}"
            create_splunk_directory(file_path)
          end
          manage_file("#{file_path}/#{file_name}", contents)
        end
      end

      # uninstall the app by removing the apps directory
      def action_remove
        app_dir = Chef::Resource::Directory.new(new_resource.root_dir, run_context)
        app_dir.path(new_resource.root_dir)
        app_dir.recursive(true)
        app_dir.run_action(:delete)
        new_resource.updated_by_last_action(app_dir.updated_by_last_action?)
      end

      def create_app_directories
        new_resource.required_directories.each do |directory|
          create_splunk_directory(directory)
        end
      end

      # function for creating a directory with the proper permissions for splunk
      def create_splunk_directory(path)
        dir = Chef::Resource::Directory.new(path, run_context)
        dir.path(path)
        dir.recursive(false)
        dir.owner(node['splunk']['user'])
        dir.group(node['splunk']['group'])
        dir.mode('0755')
        dir.run_action(:create)
        new_resource.updated_by_last_action(true) if dir.updated_by_last_action?
      end

      def manage_metaconf
        permissions = new_resource.permissions
        permissions.each do |stanza, hash|
          hash.each do |key, values|
            if values.is_a?(Hash)
              permissions[stanza][key] = values.map { |right, role| "#{right} : [ #{[*role].join(', ')} ]" }.join(', ')
            end
          end
        end
        manage_file(new_resource.perms_file, permissions)
      end

      # function for dropping either a splunk template generated from a hash
      # or a simple file if the contents are a string. If the content of the file
      # is empty, then the file will be removed
      def manage_file(path, contents)
        if contents.class == Hash && contents.empty? == false
          file = Chef::Resource::Template.new(path, run_context)
          file.cookbook('cerner_splunk')
          file.source('generic.conf.erb')
          file.variables(stanzas: contents)
        else
          file = Chef::Resource::File.new(path, run_context)
          file.content(contents)
        end
        file.path(path)
        file.owner(node['splunk']['user'])
        file.group(node['splunk']['group'])
        file.mode('0600')
        if contents.empty?
          file.run_action(:delete)
        else
          file.run_action(:create)
        end
        new_resource.updated_by_last_action(true) if file.updated_by_last_action?
      end
    end
  end
end
