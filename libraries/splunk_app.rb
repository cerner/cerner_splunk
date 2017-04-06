# coding: UTF-8

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

  # Utility Class to parse app version strings
  class AppVersion
    def initialize(version)
      @version = version.chomp.empty? ? nil : version.chomp unless version.nil?
      @base, @prerelease = @version.split(' ', 2) unless @version.nil?
      @type = @prerelease.nil? ? :base : :prerelease unless @version.nil?
    end

    attr_reader :version, :base, :prerelease, :type
    alias to_s version

    def ==(other)
      version == other.version
    end
  end
end

class Chef
  class Resource
    # Chef Resource for managing Splunk apps
    class SplunkApp < Chef::Resource
      provides :splunk_app if respond_to?(:provides)

      def initialize(name, run_context = nil)
        super
        @resource_name = :splunk_app
        @action = :create
        @allowed_actions = %i[create remove]
        @local = false
        @permissions = {}
        @lookups = {}
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

      def lookups(arg = nil)
        set_or_return(:lookups, arg, kind_of: Hash)
      end

      def permissions(arg = nil)
        set_or_return(:permissions, arg, kind_of: Hash)
      end

      def app(arg = nil)
        set_or_return(:app, arg, kind_of: String)
      end

      def url(arg = nil)
        set_or_return(:url, arg, kind_of: String)
      end

      def version(arg = nil)
        set_or_return(:version, arg, kind_of: String)
      end

      # Calculated attributes
      def required_directories
        %w[local default metadata lookups].collect { |d| "#{root_dir}/#{d}" }.unshift(root_dir)
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

      def lookup_dir
        "#{root_dir}/lookups"
      end

      def perms_file
        file_name = local ? 'local.meta' : 'default.meta'
        "#{root_dir}/metadata/#{file_name}"
      end
    end
  end
end

require_relative 'conf'

class Chef
  class Provider
    # Chef Provider for managing Splunk apps
    class SplunkApp < Chef::Provider # rubocop:disable ClassLength
      provides :splunk_app if respond_to?(:provides)

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
        download_and_install
        create_app_directories unless new_resource.updated_by_last_action?
        manage_metaconf unless new_resource.permissions.empty?
        manage_lookups unless new_resource.lookups.empty?
        new_resource.files.each do |file_name, contents|
          *directories, file_name = file_name.split('/')
          file_path = new_resource.files_dir
          directories.each do |subdir|
            file_path = "#{file_path}/#{subdir}"
            create_splunk_directory(file_path)
          end
          filename = "#{file_path}/#{file_name}"
          manage_file(filename, insert_procs(filename, contents))
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

      def should_download?(expected_version, installed_version)
        # No need to download if we already have the exact version installed
        return false if expected_version.version && expected_version == installed_version
        # We must not install a prerelease on top of the same released version
        fail "Expecting to install prerelease on top of same released version for #{new_resource.app}" if installed_version.type == :base && expected_version.base == installed_version.base
        # Warn (but not fail) if the expected version is not specified. (Optimization for us)
        Chef::Log.warn "Expected version not specified for #{new_resource.app}." unless expected_version.version
        # When in whyrun mode, we want to stop here as the rest requires the tarball to be downloaded (thus changing the node).
        !whyrun_mode?
      end

      def download_and_install
        return if new_resource.url.nil? || new_resource.url.empty?

        expected_version = CernerSplunk::AppVersion.new new_resource.version
        installed_version = CernerSplunk::AppVersion.new @current_resource.version

        return unless should_download? expected_version, installed_version

        filename = "#{Chef::Config[:file_cache_path]}/#{new_resource.app}.tgz"

        download = download_file filename, new_resource.url

        install_from_tar filename, expected_version, installed_version
      ensure
        download.run_action(:delete) if download
      end

      def validate_downloaded(tarfile)
        fail "Downloaded tarball from '#{new_resource.url}' does not contain an app named '#{new_resource.app}'" if tarfile.num_files == 0
        fail "Downloaded tarball for '#{new_resource.app}' has local entries" unless tarfile.count { |p, _| p.match %r{^[^/]+/local/.+} } == 0
      end

      def should_install?(expected_version, installed_version, tar_version) # rubocop:disable PerceivedComplexity, CyclomaticComplexity
        fail "Downloaded tarball for #{new_resource.app} does not contain a version in app.conf!" unless tar_version.version
        # If we specify an expected version (see warning in should download), the tar version must match exactly OR the expected version is the base version of the (prerelease) tar version
        if expected_version.version && tar_version != expected_version
          fail "Expected version #{expected_version} does not match tar version #{tar_version} for #{new_resource.app}" unless expected_version.type == :base && tar_version.base == expected_version.base
        end
        # If the exact version is already installed, NOOP
        return false if tar_version == installed_version
        # We must not install a prerelease on top of the same released version
        fail "Attempting to install prerelease on top of same released version for #{new_resource.app}" if installed_version.type == :base && installed_version.base == tar_version.base
        true
      end

      def install_from_tar(filename, expected_version, installed_version)
        tarfile = CernerSplunk::TarBall.new(filename, prefix: new_resource.app, user: node['splunk']['user'], group: node['splunk']['group'])

        validate_downloaded tarfile

        app_conf = CernerSplunk::Conf.parse_string tarfile.get_file('default/app.conf')
        tar_version = CernerSplunk::AppVersion.new((app_conf['launcher'] || {})['version'])

        return unless should_install? expected_version, installed_version, tar_version

        old_dir_path = "#{new_resource.root_dir}.old"

        old_dir = Chef::Resource::Directory.new(old_dir_path, run_context)
        old_dir.recursive true
        old_dir.run_action :delete

        # Move existing app out of the way
        ::File.rename new_resource.root_dir, old_dir_path if ::File.exist? new_resource.root_dir
        # Extract tarball to app directory
        tarfile.extract new_resource.apps_dir

        # Restore all potential user defined content
        create_app_directories
        if ::File.exist? old_dir_path
          ::Dir.chdir old_dir_path do
            ::Dir['local/*', 'lookups/*', 'metadata/local.meta'].each do |f|
              ::File.rename "#{old_dir_path}/#{f}", "#{new_resource.root_dir}/#{f}"
            end
          end
        end
        # Remove old app
        old_dir.run_action :delete

        new_resource.updated_by_last_action true
      ensure
        tarfile.close if tarfile
      end

      def manage_lookups
        lookups = new_resource.lookups
        lookups.each do |file_name, url|
          if url && !url.empty?
            fail "Unsupported lookup file format for #{file_name} in the app #{new_resource.app}" unless file_name =~ /\.(?:csv\.gz|csv|kmz)$/i
            download_file ::File.join(new_resource.lookup_dir, file_name), url
          else
            delete_file ::File.join(new_resource.lookup_dir, file_name)
          end
        end
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

      def download_file(file_path, url)
        download = Chef::Resource::RemoteFile.new(file_path, run_context)
        download.source(url)
        download.backup(false)
        download.run_action(:create)
      end

      def delete_file(file_path)
        download = Chef::Resource::File.new(file_path, run_context)
        download.run_action(:delete)
      end

      def symbolize_keys(hash)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      end

      def hash_to_proc(source_module, data, context = {})
        proc_sym = data['proc'].to_sym
        data = symbolize_keys(data).reject { |k, _| k == :proc }
        arguments = context.merge data
        source_module.send proc_sym, arguments
      end

      def insert_procs(filename, contents)
        return contents unless contents.is_a? Hash
        contents.inject({}) do |retval, (stanza, attributes)|
          retval[stanza] = attributes.inject({}) do |stanzavals, (key, value)|
            stanzavals[key] =
              if value.is_a? Hash
                value_proc = hash_to_proc CernerSplunk::ConfTemplate::Value, value['value'], filename: filename, node: node
                transform_proc = hash_to_proc CernerSplunk::ConfTemplate::Transform, value['transform'], filename: filename, node: node if value['transform']
                transform_proc ||= CernerSplunk::ConfTemplate::Transform.id

                CernerSplunk::ConfTemplate.compose transform_proc, value_proc
              else
                value
              end
            stanzavals
          end
          retval
        end
      end

      # function for dropping either a splunk template generated from a hash
      # or a simple file if the contents are a string. If the content of the file
      # is empty, then the file will be removed
      def manage_file(path, contents) # rubocop:disable Metrics/PerceivedComplexity
        if contents.is_a?(Hash) && !contents.empty?
          file = Chef::Resource::Template.new(path, run_context)
          file.cookbook('cerner_splunk')
          file.source('generic.conf.erb')
          file.variables(stanzas: contents)
        else
          file = Chef::Resource::File.new(path, run_context)
          file.content(contents) unless contents.empty?
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
