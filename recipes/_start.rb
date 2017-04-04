# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

ulimit_command = "ulimit -n #{node['splunk']['limits']['open_files']}"
init_file_path = '/etc/init.d/splunk'
restart_flag = !(File.exist?(init_file_path) && File.readlines(init_file_path).grep(/#{ulimit_command}/).any?)

# We want to always ensure that the boot-start script is in place on non-windows platforms
execute "#{node['splunk']['cmd']} enable boot-start -user #{node['splunk']['user']}" do
  not_if { platform_family?('windows') }
end

ruby_block 'insert ulimit' do
  block do
    file = Chef::Util::FileEdit.new(init_file_path)
    file.insert_line_after_match(/^RETVAL=\d$/, ulimit_command)
    file.write_file
  end
  not_if { platform_family?('windows') }
end

ruby_block 'restart-splunk-for-ulimit' do
  block { true }
  notifies :touch, 'file[splunk-marker]', :immediately
  only_if { !platform_family?('windows') && restart_flag }
end

# We then start splunk. In the future, the other resource should be here instead of this clumsy notification
# but we'd need to refactor the determination of the service name away from the _install recipe.
ruby_block 'start-splunk' do
  block { true }
  notifies :start, 'service[splunk]', :immediately
end

include_recipe 'cerner_splunk::_generate_password'
