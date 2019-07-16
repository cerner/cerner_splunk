# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: splunk_logs.rb
#
# Libraries for configuring splunk's internal log settings.

require 'chef/provider'
require 'chef/resource'

class Chef
  class Resource
    # Chef Resource for managing Splunk log config.
    class SplunkLogs < Chef::Resource
      provides :splunk_logs if respond_to?(:provides)

      def initialize(name, run_context = nil)
        super
        @resource_name = :splunk_logs
        @action = :create
        @allowed_actions = %i[create]
        @location = name
        @contents = {}
      end

      def location(arg = nil)
        set_or_return(:location, arg, kind_of: String)
      end

      def contents(arg = nil)
        set_or_return(:contents, arg, kind_of: Hash)
      end
    end
  end
end

require_relative 'conf'

class Chef
  class Provider
    # Chef Provider for managing Splunk log config
    class SplunkLogs < Chef::Provider
      provides :splunk_logs if respond_to?(:provides)

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource ||= Chef::Resource::SplunkLogs.new(new_resource.name)
      end

      def action_create
        manage_file(new_resource.location, 'splunkd' => new_resource.contents)
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
