
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_inputs
#
# Configures the system inputs.conf file

# Translate monitor attributes to generic hash
base_hash = { 'default' => { 'host' => node['splunk']['config']['host'] } }

input_stanzas = CernerSplunk::LWRP.convert_monitors node, node['splunk']['monitors'], node['splunk']['main_project_index'], base_hash

if %i[server cluster_slave].include? node['splunk']['node_type']
  bag = CernerSplunk.my_cluster_data(node)

  port = bag.dig('receiver_settings', 'splunktcp', 'port')
  port ||= bag.dig('receiver_settings', 'splunktcp')
  port ||= bag['receiver_settings']

  if port
    input_stanzas["splunktcp://:#{port}"] = { 'disabled' => 0, 'connection_host' => 'none' }
  else
    Chef::Log.warn "Receiver settings missing in configured cluster data bag: #{cluster}"
  end
end

splunk_conf 'system/inputs.conf' do
  config input_stanzas
  action :configure
  notifies :desired_restart, "splunk_service[#{node['splunk']['package']['type']}]", :immediately
end
