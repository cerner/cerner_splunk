# coding: UTF-8
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _restart_prep
#
# Prepares the restart resource for notifications

# TODO: Unused?
puts node['splunk']['package']['type']
splunk_restart node['splunk']['package']['type'] do
  package node['splunk']['package']['type'].to_sym
  action :nothing
end
