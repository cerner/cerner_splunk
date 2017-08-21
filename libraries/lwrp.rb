# coding: UTF-8

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
    def self.convert_monitors(monitors, default_index = nil, base = {})
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
      all_stanzas
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
  end
end
