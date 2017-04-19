# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: config_procs.rb

module CernerSplunk
  # Module for dynamically generating configuration values via Procs
  module ConfigProcs
    # Methods to generate procs for determining the value to be written to a conf file
    module Value
      def self.constant(value:, **_)
        proc { value }
      end

      def self.vault(coordinate:, default_coords: nil, pick_context: nil, **_)
        proc { CernerSplunk::DataBag.load coordinate, type: :vault, default: default_coords, pick_context: pick_context }
      end

      def self.existing(filename:, **_)
        proc do |context, config|
          config_file = CernerSplunk::ConfHelpers.read_config(filename) if filename
          config_file ||= config
          context.key ? (config_file[context.section] || {})[context.key] : config_file[context.section]
        end
      end
    end

    # Methods to generate procs for how to transform the value prior to writing.
    module Transform
      def self.id(**_)
        proc { |x| x }
      end

      def self.splunk_encrypt(node:, xor: true, **_)
        proc do |x|
          Chef::Log.error node.run_state
          Chef::Log.error node.run_state['cerner_splunk']
          Chef::Log.error node.run_state['cerner_splunk']['splunk.secret']
          CernerSplunk.splunk_encrypt_password(x, node.run_state['cerner_splunk']['splunk.secret'], xor) if x
        end
      end
    end

    def self.proc_modules
      {
        value: Value,
        transform: Transform
      }
    end

    def self.compose(g, f)
      proc { |*a| g[*f[*a]] }
    end

    def self.generate_proc(proc_type, data, context = {})
      return Transform.id if proc_type == :transform && !data.key?('transform')
      proc_modules[proc_type].send(data[proc_type.to_s].delete('proc').to_sym, context.merge(data[proc_type.to_s]))
    end

    def self.generate_and_compose_proc(data, context = {})
      compose(generate_proc(:transform, data, context), generate_proc(:value, data, context))
    end

    def self.parse(hash, **additional)
      return hash unless hash.is_a? Hash

      hash.map do |stanza, props|
        [stanza, props.map { |k, v| [k, v.is_a?(Hash) ? generate_and_compose_proc(v, additional) : v] }.to_h]
      end.to_h
    end
  end
end
