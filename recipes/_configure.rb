# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure
#
# Configures the Splunk system post package installation

# Verify that clusters are configured
if node['splunk']['node_type'] != :license_server && node['splunk']['config']['clusters'].empty?
  throw 'You need to configure at least one cluster databag.'
end

node['splunk']['config']['clusters'].each do |cluster|
  unless CernerSplunk::DataBag.load(cluster)
    throw "Unknown databag configured for node['splunk']['config]['clusters'] => '#{cluster}'"
  end
end

include_recipe 'cerner_splunk::_configure_server'
include_recipe 'cerner_splunk::_configure_roles'
include_recipe 'cerner_splunk::_configure_authentication'
include_recipe 'cerner_splunk::_configure_inputs'
include_recipe 'cerner_splunk::_configure_outputs'
include_recipe 'cerner_splunk::_configure_alerts'
include_recipe 'cerner_splunk::_configure_apps'
