# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _generate_password
#
# Generates and sets a random password for the admin splunk account.
# This recipe must be run while Splunk is running.

return if node['splunk']['free_license'] && node['splunk']['node_type'] != :forwarder

require 'securerandom'

password_file = File.join node['splunk']['external_config_directory'], 'password'

old_password = File.exist?(password_file) ? File.read(password_file) : 'changeme'
new_password = SecureRandom.hex(36)

execute 'change-admin-password' do # ~FC009
  command "#{node['splunk']['cmd']} edit user admin -password #{new_password} -roles admin -auth admin:#{old_password}"
  environment 'HOME' => node['splunk']['home']
  sensitive true
end

if platform_family?('windows')
  system_user = 'SYSTEM'
  system_group = 'SYSTEM'
else
  system_user = 'root'
  system_group = 'root'
end

file password_file do
  backup false
  owner system_user
  group system_group
  mode '0600'
  sensitive true
  content new_password
end
