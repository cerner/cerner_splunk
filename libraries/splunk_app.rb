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

        result[app_name] = app_hash
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
        set_or_return(:local, arg, kind_of: [TrueClass, FalseClass])
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
        @current_resource.files(new_resource.files)
        @current_resource.permissions(new_resource.permissions)
        @current_resource.app(new_resource.app)
        @current_resource.action(new_resource.action)
        @current_resource
      end

      def action_create
        @root_dir = "#{@current_resource.apps_dir}/#{@current_resource.app}"
        create_app_directories
        manage_metaconf unless @current_resource.permissions.empty?
        @current_resource.files.each do |file_name, contents|
          *directories, file_name = file_name.split('/')
          file_path = @current_resource.local ? "#{@root_dir}/local" : "#{@root_dir}/default"
          directories.each do |subdir|
            file_path = "#{file_path}/#{subdir}"
            create_splunk_directory(file_path)
          end
          manage_file(file_name, contents, file_path)
        end
      end

      # uninstall the app by removing the apps directory
      def action_remove
        app_dir = Chef::Resource::Directory.new("#{@current_resource.apps_dir}/#{@current_resource.app}", run_context)
        app_dir.path("#{@current_resource.apps_dir}/#{@current_resource.app}")
        app_dir.recursive(true)
        app_dir.run_action(:delete)
        new_resource.updated_by_last_action(app_dir.updated_by_last_action?)
      end

      def create_app_directories
        create_splunk_directory(@root_dir)
        %w(local default metadata).each do |directory|
          create_splunk_directory("#{@root_dir}/#{directory}")
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
        new_resource.updated_by_last_action(dir.updated_by_last_action?)
      end

      def manage_metaconf
        file_name = @current_resource.local ? 'local.meta' : 'default.meta'
        file_path = "#{@current_resource.apps_dir}/#{@current_resource.app}/metadata/"
        permissions = @current_resource.permissions
        permissions.each do |stanza, hash|
          hash.each do |key, values|
            if values.is_a?(Hash)
              permissions[stanza][key] = values.map { |right, role| "#{right} : [ #{[*role].join(', ')} ]" }.join(', ')
            end
          end
        end
        manage_file(file_name, permissions, file_path)
      end

      # function for dropping either a splunk template generated from a hash
      # or a simple file if the contents are a string. If the content of the file
      # is empty, then the file will be removed
      def manage_file(file_name, contents, path)
        if contents.class == Hash && contents.empty? == false
          file = Chef::Resource::Template.new("#{path}/#{file_name}", run_context)
          file.cookbook('cerner_splunk')
          file.source('generic.conf.erb')
          file.variables(stanzas: contents)
        else
          file = Chef::Resource::File.new("#{path}/#{file_name}", run_context)
          file.content(contents)
        end
        file.path("#{path}/#{file_name}")
        file.owner(node['splunk']['user'])
        file.group(node['splunk']['group'])
        file.mode('0600')
        if contents.empty?
          file.run_action(:delete)
        else
          file.run_action(:create)
        end
        new_resource.updated_by_last_action(file.updated_by_last_action?)
      end
    end
  end
end
