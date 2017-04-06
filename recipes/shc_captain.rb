# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: shc_captain
#

fail 'Captain installation not currently supported on windows' if platform_family?('windows')

search_heads = CernerSplunk.my_cluster_data(node)['shc_members']

fail 'Search Heads are not configured for sh clustering in the cluster databag' if search_heads.nil? || search_heads.empty?

instance_exec :shc_captain, &CernerSplunk::NODE_TYPE
## Recipes
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_start'

cerner_splunk_sh_cluster 'Captain assignment' do
  search_heads search_heads
  admin_password(lazy { node.run_state['cerner_splunk']['admin-password'] })
  action :initialize
  sensitive true
end
