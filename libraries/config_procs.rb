# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: config_procs.rb

module CernerSplunk
  # Module for dynamically generating configuration values via Procs
  module ConfigProcs
    # Compose two procs... I should monkey patch this in, but changing core ruby just seems wrong
    def self.compose(g, f)
      proc { |*a| g[*f[*a]] }
    end

    # Methods to generate procs for determining the value to be written to a conf file
    module Value
      def self.constant(value:, **_)
        proc { value }
      end

      def self.vault(coordinate:, default_coords: nil, pick_context: nil, **_)
        proc { CernerSplunk::DataBag.load coordinate, type: :vault, default: default_coords, pick_context: pick_context }
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
