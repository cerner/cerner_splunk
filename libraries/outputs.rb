
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# File Name:: outputs.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure outputs.conf in a Splunk system
  module Outputs
    def self.configure_outputs(node) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      output_stanzas = {}

      if %i[search_head forwarder cluster_master shc_deployer].include? node['splunk']['node_type']
        output_stanzas['tcpout'] = {
          'forwardedindex.0.whitelist' => '.*',
          'forwardedindex.1.blacklist' => '_thefishbucket',
          'forwardedindex.2.whitelist' => ''
        }

        # If we're part of a cluster, we only want to send events to our cluster.
        if node['splunk']['node_type'] == :forwarder
          CernerSplunk.all_clusters(node)
        else
          [CernerSplunk.my_cluster(node)]
        end.each do |(cluster, bag)|
          port = bag['receiver_settings']
          port = port['splunktcp'] if port
          port = port['port'] if port
          receivers = bag['receivers']

          if !receivers || receivers.empty? || !port
            Chef::Log.warn "Receiver settings missing or incomplete in configured cluster data bag: #{cluster}"
          else
            output_stanzas["tcpout:#{cluster}"] = {}
            output_stanzas["tcpout:#{cluster}"]['server'] = receivers.collect do |x|
              x.include?(':') ? x : "#{x}:#{port}"
            end.join(',')
          end
        end
      end
      output_stanzas
    end
  end
end
