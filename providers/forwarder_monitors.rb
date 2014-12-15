# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Provider:: forwarder_monitors
#
# Drop in replacement for the existing splunk_forwarder_monitors

action :install do # ~FC017
  input_stanzas = CernerSplunk::LWRP.convert_monitors(node, new_resource.monitors, new_resource.index)

  splunk_app new_resource.app do
    apps_dir "#{node['splunk']['home']}/etc/apps"
    action :create
    local true
    files 'inputs.conf' => input_stanzas
    notifies :restart, 'service[splunk]'
  end
end

action :delete do  # ~FC017
  splunk_app new_resource.app do
    apps_dir "#{node['splunk']['home']}/etc/apps"
    action :remove
    notifies :restart, 'service[splunk]'
  end
end
