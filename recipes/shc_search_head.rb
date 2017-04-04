# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: shc_search_head
#
# Configures a Search Head in a SHC

fail 'Search Head installation not currently supported on windows' if platform_family?('windows')

search_heads = CernerSplunk.my_cluster_data(node)['shc_members']
fail 'Search Heads are not configured for sh clustering in the cluster databag' if search_heads.nil? || search_heads.empty?
## Attributes
instance_exec :shc_search_head, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_start'

cerner_splunk_sh_cluster 'add SH to SHC' do
  search_heads search_heads
  admin_password(lazy { node.run_state['cerner_splunk']['admin-password'] })
  not_if { node['splunk']['bootstrap_shc_member'] }
  sensitive true
end
