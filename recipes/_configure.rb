# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure
#
# Configures the Splunk system post package installation

unless node.run_state['cerner_splunk']['configure_apps_only']
  # Verify that clusters are configured
  if node['splunk']['node_type'] != :license_server && node['splunk']['config']['clusters'].empty?
    if node['splunk']['node_type'] == :forwarder
      Chef::Log.warn 'No cluster data bag configured, ensure your outputs are configured elsewhere.'
    else
      throw 'You need to configure at least one cluster databag.'
    end
  end

  node['splunk']['config']['clusters'].each do |cluster|
    unless CernerSplunk::DataBag.load(cluster, secret: node['splunk']['data_bag_secret'])
      throw "Unknown databag configured for node['splunk']['config]['clusters'] => '#{cluster}'"
    end
  end

  include_recipe 'cerner_splunk::_configure_server'
  include_recipe 'cerner_splunk::_configure_roles'
  include_recipe 'cerner_splunk::_configure_authentication'
  include_recipe 'cerner_splunk::_configure_inputs'
  include_recipe 'cerner_splunk::_configure_outputs'
  include_recipe 'cerner_splunk::_configure_alerts'
end

include_recipe 'cerner_splunk::_configure_apps'
