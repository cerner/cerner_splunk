# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: conf_template.rb
module CernerSplunk
  unless defined?(ConfTemplate)
    # Module for generating template data
    module ConfTemplate
      # Evaluate a Proc (or a Proc returning Procs)
      def self.collapse_proc(initial, depth: 10, arguments: {}, label: nil)
        value = initial
        message_suffix = " evaluating #{label}" unless label.nil?
        while value.is_a? Proc
          fail "Proc depth exceeded#{message_suffix}" if depth <= 0
          value = value.call(arguments)
          depth -= 1
        end
        value
      end

      # Convert the stanzas argument into Hash of Hash of key value pairs
      def self.convert_stanzas(input)
        (CernerSplunk::ConfTemplate.collapse_proc input || {}).inject({}) do |file_data, (stanza, stanza_value)|
          label = "Stanza #{stanza}"
          stanza_value = CernerSplunk::ConfTemplate.collapse_proc stanza_value, label: label, arguments: { stanza: stanza }
          fail "Unexpected value (#{stanza_value.class} '#{stanza_value}') for #{label}" unless stanza_value.nil? || stanza_value.is_a?(Hash)
          if stanza_value.is_a? Hash
            file_data[stanza] = stanza_value.inject({}) do |result, (attribute, value)|
              label = "Attribute #{attribute}, Stanza #{stanza}"
              value = CernerSplunk::ConfTemplate.collapse_proc value, label: label, arguments: { stanza: stanza, attribute: attribute }
              result[attribute] = value unless value.nil?
              result
            end
          end
          file_data
        end
      end

      # Compose two procs... I should monkey patch this in, but changing core ruby just seems wrong
      def self.compose(g, f)
        proc { |*a| g[*f[*a]] }
      end

      # Class to cache the read of a conf file's existing contents
      class ExistingValue
        def initialize(filename)
          @reader = CernerSplunk::Conf::Reader.new filename
        end

        def [](x)
          data[x]
        end

        def data
          @data ||= @reader.read
        end
      end

      # Methods to generate procs for determining the value to be written to a conf file
      module Value
        def self.constant(value:, **_)
          proc { value }
        end

        def self.vault(coordinate:, default_coords: nil, pick_context: nil, node:, **_)
          proc { CernerSplunk::DataBag.load coordinate, secret: node['splunk']['data_bag_secret'], default: default_coords, pick_context: pick_context }
        end

        def self.existing(filename:, **_)
          @file_readers ||= Hash.new { |hash, key| hash[key] = CernerSplunk::ConfTemplate.ExistingValue.new key }
          existing_value = @file_readers[filename]
          proc { |stanza:, attribute: nil, **_| attribute.nil? ? existing_value[stanza] : (existing_value[stanza] || {})[attribute] }
        end
      end

      # Methods to generate procs for how to transform the value prior to writing.
      module Transform
        def self.id(**_)
          proc { |x| x }
        end

        def self.splunk_encrypt(node:, xor: true, **_)
          proc { |x| CernerSplunk.splunk_encrypt_password(x, node.run_state['cerner_splunk']['splunk.secret'], xor) if x }
        end
      end
    end
  end
end
