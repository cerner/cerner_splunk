# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: search_head
#
# Configures a Search Head

## Attributes
instance_exec :search_head, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_configure_ui'
include_recipe 'cerner_splunk::_start'
