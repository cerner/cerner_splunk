# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: passive_sensitive.rb

require 'chef/resource'

class Chef # rubocop:disable Style/MultilineIfModifier
  # Making the sensitive attribute passive for older chef versions
  class Resource # rubocop:disable Documentation
    def sensitive(args = nil)
      set_or_return(:sensitive, args, kind_of: [TrueClass, FalseClass])
    end
  end
end unless Chef::Resource.method_defined? :sensitive
