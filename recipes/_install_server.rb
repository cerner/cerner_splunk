
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _install_server
#
# Installs the full Splunk package.

## Attributes
node.default['splunk']['package']['base_name'] = 'splunk'

## Recipes
include_recipe 'cerner_splunk::_install'
