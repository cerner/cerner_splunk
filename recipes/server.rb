# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: server
#
# Configures Splunk as a Standalone server (Indexer, Receiver, Search Head, Slave)

fail 'Server installation not currently supported on windows' if platform_family?('windows')

## Attributes
instance_exec :server, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_configure_indexes'
include_recipe 'cerner_splunk::_configure_ui'
include_recipe 'cerner_splunk::_start'
