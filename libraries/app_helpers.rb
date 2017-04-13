
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: app_helpers.rb

module CernerSplunk # rubocop:disable Style/Documentation
  unless defined?(AppHelpers)
    # Helper library for managing Splunk apps
    module AppHelpers
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

      def self.proc_files(**params)
        files = (params[:files] || {}).select { |key, _| key.to_s =~ /.+(?<!\.conf)$/ }
        lookups = params[:lookups] || {}

        proc do |app_base|
          app_path = Pathname.new app_base

          files.each do |file, contents|
            file_path = app_path + file

            directory file_path.to_s do
              owner node['splunk']['user']
              group node['splunk']['group']
              mode '0755'
              recursive true
            end

            file file_path.to_s do
              owner node['splunk']['user']
              group node['splunk']['group']
              mode '0600'
              content CernerSplunk::ConfigProcs.parse(contents, filename: file_path)
              action contents.empty? ? :delete : :create
            end
          end

          lookups.each do |file, url|
            file_path = app_path + 'lookups' + file

            directory file_path.to_s do
              owner node['splunk']['user']
              group node['splunk']['group']
              mode '0755'
            end

            remote_file file_path.to_s do
              if (url ||= '').empty?
                action :delete
              else
                raise "Unsupported lookup file format for #{file}" unless file =~ /\.(?:csv\.gz|csv|kmz)$/i
                owner node['splunk']['user']
                group node['splunk']['group']
                mode '0600'
              end
            end
          end
        end
      end

      def self.proc_conf(files)
        conf_files = files.select { |key, _| key.to_s =~ /.+\.conf$/ }

        proc do
          conf_files.each do |file, desired_config|
            splunk_conf file do
              config desired_config
            end
          end
        end
      end
    end
  end
end
