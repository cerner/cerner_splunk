# Cookbook Name:: cerner_splunk
# Recipe:: server_install_only
#
# Only run the basic install for the purposes of baking a base server image. Skips
# the vast majority of configuration since it's likely environment specific.
#

fail 'Server installation not currently supported on windows' if platform_family?('windows')

## Attributes
instance_exec :server, &CernerSplunk::NODE_TYPE
node.run_state['cerner_splunk']['configure_apps_only'] = true

include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_start'
include_recipe 'cerner_splunk::image_prep'
