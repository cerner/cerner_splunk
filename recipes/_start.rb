# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: _start
#
# Ensures the splunk instance is running, and performs post-start tasks.

ulimit_command = "ulimit -n #{node['splunk']['limits']['open_files']}"
init_file_path = '/etc/init.d/splunk'
restart_flag = !(File.exist?(init_file_path) && File.readlines(init_file_path).grep(/#{ulimit_command}/).any?)

# We want to always ensure that the boot-start script is in place on non-windows platforms
command = "#{node['splunk']['cmd']} enable boot-start -user #{node['splunk']['user']}"
command += node['splunk']['boot_start_args'] if Gem::Version.new(node['splunk']['package']['version']) >= Gem::Version.new('7.2.2')

execute command do
  not_if { platform_family?('windows') }
  not_if { File.exist?(node['splunk']['systemd_file_location']) }
end

ruby_block 'update-initd-file' do
  block do
    file = Chef::Util::FileEdit.new(init_file_path)
    file.insert_line_after_match(/^RETVAL=\d$/, ulimit_command)
    file.insert_line_after_match(/^#{ulimit_command}$/, "USER=#{node['splunk']['user']}")
    file.search_file_replace(%r{"[$\w\/]+\/bin\/splunk" start --no-prompt --answer-yes}, "su - ${USER} -c '\\0'")
    file.search_file_replace(%r{"[$\w\/]+\/bin\/splunk" (stop|restart|status)}, "su - ${USER} -c '\\0'")
    file.write_file
  end
  only_if { File.exist?(init_file_path) }
end

ruby_block 'restart-splunk-for-initd-ulimit' do
  block { true }
  notifies :touch, 'file[splunk-marker]', :immediately
  only_if { !platform_family?('windows') && restart_flag && !File.exist?(node['splunk']['systemd_file_location']) }
end

execute 'reload-systemctl' do
  command 'systemctl daemon-reload'
  action :nothing
end

filter_lines 'update-systemd-file' do
  path node['splunk']['systemd_file_location']
  filters([
            { stanza: ['Service', { KillMode: 'mixed', KillSignal: 'SIGINT', TimeoutStopSec: '10min' }] }
          ])
  sensitive false
  only_if { File.exist?(node['splunk']['systemd_file_location']) }
  notifies :run, 'execute[reload-systemctl]', :immediately
end

# We then start splunk. In the future, the other resource should be here instead of this clumsy notification
# but we'd need to refactor the determination of the service name away from the _install recipe.
ruby_block 'start-splunk' do
  block { true }
  notifies :start, 'service[splunk]', :immediately
end

# The first time splunk is started on linux using chef the .pid file is owned by root which causes issues.
pid_file = "#{node['splunk']['home']}/var/run/splunk/splunkd.pid"
file pid_file do
  owner node['splunk']['user']
  group node['splunk']['group']
  only_if { File.exist? pid_file }
end

include_recipe 'cerner_splunk::_generate_password'
