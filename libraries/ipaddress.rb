# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: ipaddress.rb

require 'json'

module CernerSplunk
  # Module contains functions to configure ipaddresses in a Splunk system
  module IPaddress
    def self.management_ipaddress(node)
      addresses_hash = node['network']['interfaces'][node['splunk']['mgmt_interface']]['addresses']
      management_ipaddress = addresses_hash.select { |_, v| v['family'] == 'inet' }.keys.first
      management_ipaddress
    end
  end
end
