# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _install_server
#
# Installs the full Splunk package.

## Attributes
node.default['splunk']['package']['base_name'] = 'splunk'
node.default['splunk']['package']['download_group'] = 'splunk'

## Recipes
include_recipe 'cerner_splunk::_install'
