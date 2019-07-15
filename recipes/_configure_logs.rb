# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_logs
#
# Configures the system log-local.cfg file

log_local_contents = node['splunk']['logs']

splunk_logs '/opt/splunk/etc/log-local.cfg' do
  contents log_local_contents
  notifies :touch, 'file[splunk-marker]', :immediately
end
