# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_logs
#
# Configures the system log-local.cfg file

log_local_contents = node['splunk']['logs']

splunk_template 'etc/log-local.cfg' do
  stanzas log_local_contents
  notifies :touch, 'file[splunk-marker]', :immediately
end
