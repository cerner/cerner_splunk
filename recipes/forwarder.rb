# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: forwarder
#
# Installs the Universal Forwarder.

## Attributes
instance_exec :forwarder, &CernerSplunk::NODE_TYPE

node.default['splunk']['package']['base_name'] = 'splunkforwarder'
node.default['splunk']['package']['download_group'] = 'universalforwarder'

fail 'Different Splunk artifact already installed on node. Failing as an unsupported install' if CernerSplunk.separate_splunk_installed?(node) && !node['splunk']['ignore_already_installed_instance']

## Recipes
include_recipe 'cerner_splunk::_install'
include_recipe 'cerner_splunk::_start'
