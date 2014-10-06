# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: cluster_master
#
# Install a Splunk Cluster Master.

## Attributes
instance_exec :cluster_master, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'

password_file = File.join node[:splunk][:external_config_directory], 'password'

execute 'apply-cluster-bundle' do
  command "cat #{password_file} | xargs #{node[:splunk][:cmd]} apply cluster-bundle --answer-yes -auth admin:"
  action :nothing
end

include_recipe 'cerner_splunk::_configure_indexes'
include_recipe 'cerner_splunk::_start'
