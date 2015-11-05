# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: heavy_forwarder
#
# Installs the Heavy Forwarder.

fail 'Heavy Forwarder installation not currently supported on windows' if platform_family?('windows')

## Attributes
instance_exec :heavy_forwarder, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_cleanup_forwarder'
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_start'
