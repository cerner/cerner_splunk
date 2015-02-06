# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: passive_sensitive.rb

require 'chef/resource'

# rubocop:disable Documentation
class Chef
  # Making the sensitive attribute passive for older chef versions
  class Resource
    def sensitive(_ = nil)
    end
  end
end unless Chef::Resource.method_defined? :sensitive
# rubocop:enable Documentation
