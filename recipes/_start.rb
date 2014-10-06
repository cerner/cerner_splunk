# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

execute "#{node[:splunk][:cmd]} enable boot-start -user #{node[:splunk][:user]}" do
  notifies :start, 'service[splunk]', :immediately
end

directory node[:splunk][:external_config_directory] do
  owner node[:splunk][:user]
  group node[:splunk][:group]
  mode '0700'
end

include_recipe 'cerner_splunk::_generate_password'
