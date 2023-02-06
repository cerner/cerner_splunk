# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: _generate_password
#
# Generates and sets a random password for the admin splunk account.
# This recipe must be run while Splunk is running.

return if node['splunk']['free_license'] && node['splunk']['node_type'] != :forwarder

require 'securerandom'

# For a node that has multiple splunk instances, create a separate password file.
password_file = if node['splunk']['ignore_already_installed_instance'] == true
                  File.join node['splunk']['external_config_directory'], 'password_forwarder'
                else
                  File.join node['splunk']['external_config_directory'], 'password'
                end

old_password = File.exist?(password_file) ? File.read(password_file) : 'changeme'

admin_hash = node['splunk']['config']['admin_password']
key = CernerSplunk.keys(node).find { |x| admin_hash.key?(x.to_s) } if admin_hash
new_password = CernerSplunk::DataBag.load admin_hash[key], secret: node['splunk']['data_bag_secret'], handle_load_failure: true if key
new_password ||= SecureRandom.hex(36)

node.run_state['cerner_splunk']['admin-password'] = old_password

ruby_block 'update admin password in run_state' do
  block do
    node.run_state['cerner_splunk']['admin-password'] = new_password
  end
  action :nothing
end

execute 'change-admin-password' do # ~FC009
  command "#{node['splunk']['cmd']} edit user admin -password #{new_password} -roles admin -auth admin:#{old_password}"
  environment 'HOME' => node['splunk']['home']
  sensitive true
  not_if { new_password == old_password }
  notifies :run, 'ruby_block[update admin password in run_state]', :immediately
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
