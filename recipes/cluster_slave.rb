# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: cluster_slave
#
# Install a Splunk Cluster Slave.

## Attributes
instance_exec :cluster_slave, &CernerSplunk::NODE_TYPE

## Recipes
include_recipe 'cerner_splunk::_install_server'
include_recipe 'cerner_splunk::_start'
