# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_outputs
#
# Configures the system outputs.conf file

output_stanzas = {}

if [:search_head, :forwarder, :cluster_master].include? node[:splunk][:node_type]
  output_stanzas['tcpout'] = {
    'forwardedindex.0.whitelist' => '.*',
    'forwardedindex.1.blacklist' => '_.*',
    'forwardedindex.2.whitelist' => '(_audit|_internal)'
  }

  # If we're part of a cluster, we only want to send events to our cluster.
  if node[:splunk][:node_type] == :forwarder
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

splunk_template 'system/outputs.conf' do
  stanzas output_stanzas
  not_if { output_stanzas.empty? }
  notifies :restart, 'service[splunk]'
end
