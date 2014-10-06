# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Provider:: forwarder_monitors
#
# Drop in replacement for the existing splunk_forwarder_monitors

def app_dir
  "#{node[:splunk][:home]}/etc/apps/#{new_resource.app}"
end

action :install do
  input_stanzas = CernerSplunk::LWRP.convert_monitors(node, new_resource.monitors, new_resource.index)

  directory app_dir do
    owner node[:splunk][:user]
    group node[:splunk][:group]
    mode '0700'
  end

  directory "#{app_dir}/local" do
    owner node[:splunk][:user]
    group node[:splunk][:group]
    mode '0700'
  end

  splunk_template "apps/#{new_resource.app}/inputs.conf" do
    stanzas input_stanzas
    notifies :restart, 'service[splunk]'
  end
end

action :delete do
  directory app_dir do
    action :delete
    recursive true
    notifies :restart, 'service[splunk]'
  end
end
