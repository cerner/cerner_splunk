# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.
# TODO: Remove this recipe. It's entirely redundant, call splunk_service directly instead.

ruby_block 'start-splunk' do
  block { true }
  notifies :start, "splunk_service[#{node['splunk']['package']['type']}]", :immediately
end

include_recipe 'cerner_splunk::_generate_password'
