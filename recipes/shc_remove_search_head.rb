# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: shc_remove_search_head
#
# Configures a Search Head in a SHC

# Set the attribute to true so that the SH doesn't get added back to the cluster
node.default['splunk']['bootstrap_shc_member'] = true

include_recipe 'cerner_splunk::shc_search_head'

cerner_splunk_sh_cluster 'remove SH from SHC' do
  admin_password(lazy { node.run_state['cerner_splunk']['admin-password'] })
  action :remove
  sensitive true
end

ruby_block 'splunk-stop' do
  block { true }
  notifies :stop, 'service[splunk]', :immediately
end
