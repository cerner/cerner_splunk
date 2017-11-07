# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_inputs
#
# Configures the system inputs.conf file

# Translate monitor attributes to generic hash
base_hash = { 'default' => { 'host' => node['splunk']['config']['host'] } }

input_stanzas = CernerSplunk::LWRP.convert_monitors node['splunk']['monitors'], node['splunk']['main_project_index'], base_hash

if %i[server cluster_slave].include? node['splunk']['node_type']
  cluster, bag = CernerSplunk.my_cluster(node)
  port = bag['receiver_settings']
  port = port['splunktcp'] if port
  port = port['port'] if port
  if port
    input_stanzas["splunktcp://#{port}"] = {}
    input_stanzas["splunktcp://#{port}"]['disabled'] = 0
    input_stanzas["splunktcp://#{port}"]['connection_host'] = 'none'
  else
    Chef::Log.warn "Receiver settings missing in configured cluster data bag: #{cluster}"
  end
end

splunk_template 'system/inputs.conf' do
  stanzas input_stanzas
  notifies :touch, 'file[splunk-marker]', :immediately
end
