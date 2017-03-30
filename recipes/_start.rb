
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

ruby_block 'start service' do
  block { true }
  notifies :start, 'splunk_service[splunk service]', :immediately
end

include_recipe 'cerner_splunk::_generate_password'
