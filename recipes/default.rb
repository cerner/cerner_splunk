# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: default
#
# Default recipe. Alias of the (universal) forwarder since that's the 95% case.

include_recipe 'cerner_splunk::forwarder'
