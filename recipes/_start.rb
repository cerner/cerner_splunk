# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

ulimit_command = "ulimit -n #{node['splunk']['limits']['open_files']}"
init_file_path = '/etc/init.d/splunk'
restart_flag = !(File.exist?(init_file_path) && File.readlines(init_file_path).grep(/#{ulimit_command}/).any?)

# We want to always ensure that the boot-start script is in place on non-windows platforms
command = "#{node['splunk']['cmd']} enable boot-start -user #{node['splunk']['user']}"
if Gem::Version.new(node['splunk']['package']['version']) >= Gem::Version.new('7.2.2')
  command += node['splunk']['boot_start_args']
end
execute command do
  not_if { platform_family?('windows') }
  not_if { File.exist?(node['splunk']['systemd_file_location']) }
end

ruby_block 'insert ulimit' do
  block do
    file = Chef::Util::FileEdit.new(init_file_path)
    file.insert_line_after_match(/^RETVAL=\d$/, ulimit_command)
    file.write_file
  end
  not_if { platform_family?('windows') }
  not_if { Gem::Version.new(node['splunk']['package']['version']) >= Gem::Version.new('7.2.2') && node['platform_version'].to_i == 7 }
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

# Added in because the first time splunk is started using chef and systemd the .pid file is owned by root which causes issues. It is automatically correct when splunk is restarted.
execute 'correct permissions' do
  command "chown -RP #{node['splunk']['user']}:#{node['splunk']['group']} #{node['splunk']['home']}"
  action :run
  not_if { platform_family?('windows') }
  only_if { Gem::Version.new(node['splunk']['package']['version']) >= Gem::Version.new('7.2.2') && node['platform_version'].to_i == 7 }
end

include_recipe 'cerner_splunk::_generate_password'
