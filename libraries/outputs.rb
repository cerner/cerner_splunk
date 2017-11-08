# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: outputs.rb

require_relative 'databag'

module CernerSplunk
  # Module contains functions to configure outputs.conf in a Splunk system
  module Outputs
    def self.configure_outputs(node) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
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
          if bag['indexer_discovery'] == true
            Chef::Log.warn "Configured ['receivers'] in cluster #{cluster} will be ignored since ['indexer_discovery'] is set to true." if bag['receivers']

            indexer_discovery_settings = ((bag['indexer_discovery_settings'] && bag['indexer_discovery_settings']['outputs_configs']) || {}).reject do |k, _|
              k.start_with?('_cerner_splunk')
            end
            output_stanzas["indexer_discovery:#{cluster}"] = indexer_discovery_settings

            fail "master_uri is missing in the cluster databag: #{cluster}" if bag['master_uri'].nil? || bag['master_uri'].empty?

            output_stanzas["indexer_discovery:#{cluster}"]['master_uri'] = bag['master_uri']
            encrypt_password = CernerSplunk::ConfTemplate::Transform.splunk_encrypt node: node

            pass =
              if bag['indexer_discovery_settings'] && bag['indexer_discovery_settings']['pass4SymmKey']
                bag['indexer_discovery_settings']['pass4SymmKey']
              else
                'changeme'
              end
            output_stanzas["indexer_discovery:#{cluster}"]['pass4SymmKey'] = CernerSplunk::ConfTemplate.compose encrypt_password, CernerSplunk::ConfTemplate::Value.constant(value: pass)
            output_stanzas["tcpout:#{cluster}"] = bag['tcpout_settings'] || {}
            output_stanzas["tcpout:#{cluster}"]['indexerDiscovery'] = cluster
            next
          end

          port = bag['receiver_settings']
          port = port['splunktcp'] if port
          port = port['port'] if port
          receivers = bag['receivers']

          if !receivers || receivers.empty? || !port
            Chef::Log.warn "Receiver settings missing or incomplete in configured cluster data bag: #{cluster}"
          else
            output_stanzas["tcpout:#{cluster}"] = bag['tcpout_settings'] || {}
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
