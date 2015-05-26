# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_limits
#
# Configures the limits.conf settings for the system

splunk_template 'system/limits.conf' do
  stanzas node['splunk']['config']['limits']
  notifies :restart, 'service[splunk]'
end
