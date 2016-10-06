# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _restart_prep
#
# Prepares the restart resource for notifications

puts node['splunk']['package']['type']
splunk_restart 'splunk restart' do
  package node['splunk']['package']['type'] # I think Chefspec is not playing nice with symbols
  action :nothing
end
