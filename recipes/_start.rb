# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

# We want to always ensure that the boot-start script is in place on non-windows platforms
execute "#{node['splunk']['cmd']} enable boot-start -user #{node['splunk']['user']}" do
  not_if { platform_family?('windows') }
end

# We then start splunk. In the future, the other resource should be here instead of this clumsy notification
# but we'd need to refactor the determination of the service name away from the _install recipe.
ruby_block 'start-splunk' do
  block { true }
  notifies :start, 'service[splunk-start]', :immediately
end

include_recipe 'cerner_splunk::_generate_password'
