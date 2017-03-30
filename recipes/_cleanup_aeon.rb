
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _cleanup_aeon
#
# Removes the side-effects from the Aeon Forwarder

return if platform_family?('windows') || !node['splunk']['cleanup']

ruby_block 'clean-bashrc' do
  block do
    begin
      rc = Chef::Util::FileEdit.new('/etc/bashrc')
    rescue ArgumentError
      next # noop - If /etc/bashrc doesn't exist or is empty, that's ok
    end
    rc.search_file_delete(%r{source /.*/bin/setSplunkEnv})
    rc.write_file
  end
end

forwarder_splunk = '/opt/splunkforwarder/bin/splunk'
uninstall_tar_forwarder = !File.exist?(node['splunk']['external_config_directory']) && File.exist?(forwarder_splunk)

ruby_block 'uninstall-tar-forwarder' do
  block do
    # noop - this resource only exists to notify other resources
  end
  only_if { uninstall_tar_forwarder }
  notifies :stop, 'service[aeon-forwarder]', :immediately
  notifies :run, 'execute[disable-tar-boot-start]', :immediately
  notifies :delete, 'directory[tar-dir]', :immediately
end

service 'aeon-forwarder' do
  service_name 'splunk'
  pattern 'splunkd'
  action :nothing
  provider Chef::Provider::Service::Init if platform_family?('rhel', 'fedora')
  supports status: false, start: true, stop: true, restart: true
end

execute 'disable-tar-boot-start' do
  action :nothing
  command "#{forwarder_splunk} disable boot-start"
end

directory 'tar-dir' do
  action :nothing
  path '/opt/splunkforwarder'
  recursive true
end
