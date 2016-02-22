# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: lwrp.rb
#
# This file contains modules that can be used to extend the LWRP DSL.
# Most will follow the pattern of in order to use, include at the top of your resource / provider:
#
# extend CernerSplunk::LWRP::(module) unless defined? (method name)

require_relative 'databag'
require_relative 'recipe'

module CernerSplunk
  # Methods involved with augmenting the LWRP syntax / writing recipies
  module LWRP
    # Change a list of monitors to a hash of stanzas for writing to a config file
    def self.convert_monitors(node, monitors, default_index = nil, base = {})
      all_stanzas = monitors.inject(base) do |stanzas, element|
        type = element['type'] || element[:type] || 'monitor'
        path = element['path'] || element[:path]

        base_hash = default_index ? { 'index' => default_index } : {}
        stanzas["#{type}://#{path}"] = element.inject(base_hash) do |hash, (key, value)|
          case key
          when 'type', 'path', :type, :path
            # skip-these
          else
            hash[key.to_s] = value
          end
          hash
        end
        stanzas
      end
      validate_indexes(node, all_stanzas)
    end

    # RESOURCE: extend CernerSplunk::LWRP::DelayableAttribute unless defined? delayable_attribute
    #
    # Extension of the Resource DSL, defines an attribute that can be set upfront or can be calculated at convergence time.
    module DelayableAttribute
      def delayable_attribute(attr_name, validation = {}) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
        class_eval(<<-SHIM, __FILE__, __LINE__)
          def #{attr_name}(arg=nil,&block)
            _set_or_return_#{attr_name}(arg,block)
          end
        SHIM

        define_method("_set_or_return_#{attr_name}".to_sym) do |arg, block|
          fail "Specify only the arg or block, not both for #{attr_name}!" if arg && block

          iv_symbol = "@#{attr_name}".to_sym

          if block
            instance_variable_set(iv_symbol, block)
          elsif arg || !instance_variable_defined?(iv_symbol)
            opts = validate({ attr_name => arg }, { attr_name => validation })
            instance_variable_set(iv_symbol, opts[attr_name])
          else
            val = instance_variable_get(iv_symbol)
            if val.is_a? Proc
              validate({ attr_name => val.call }, { attr_name => validation })[attr_name]
            else
              val
            end
          end
        end
      end
    end

    # Validate the indexes to which data is being forwarded to
    def self.validate_indexes(node, monitors) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
      index_error = []
      input_regex = /^(?:monitor|tcp|batch|udp|fifo|script|fschange)/

      indexes = monitors.select { |key, _| input_regex.match(key) }.collect { |_, v| v['index'] || node['splunk']['config']['assumed_index'] }.uniq

      CernerSplunk.all_clusters(node).each do |(cluster, data_bag)|
        bag = CernerSplunk::DataBag.load(data_bag['indexes'], handle_load_failure: true)

        # Check if the indexes is not listed in the cluster data bag
        unless bag
          Chef::Log.warn "The indexes in the cluster '#{cluster}' is not defined or could not be loaded, therefore index checks could not be performed"
          next
        end

        indexes.each do |index|
          # Check if the index is not defined in the data bag
          unless bag['config'].key?(index)
            index_error << "Index '#{index}' is not defined by chef in cluster '#{cluster}'"
            next
          end

          index_states = %w(isReadOnly disabled deleted)

          index_states.each do |state|
            value = bag['config'][index][state]
            if value && %w(1 true).include?(value.to_s)
              index_error << "Cannot forward data to index '#{index}' in the cluster '#{cluster}', because the index is marked as '#{state}'"
            end
          end
        end
      end

      unless index_error.empty?
        index_error_msg = "Data cannot be forwarded to respective index(es) due to the following reason(s):\n#{index_error.join("\n")}"
        fail index_error_msg if node['splunk']['flags']['index_checks_fail']
        Chef::Log.warn index_error_msg
      end

      monitors
    end
  end
end
