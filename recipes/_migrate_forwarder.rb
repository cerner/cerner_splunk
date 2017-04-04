# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _migrate_forwarder
#
# Migrates from the Universal Forwarder to a heavy forwarder

require 'fileutils'

opposite_package_name = CernerSplunk.opposite_package_name(node['splunk']['package']['base_name'])

service 'splunk' do
  service_name CernerSplunk.splunk_service_name(node['platform_family'], opposite_package_name)
  action :stop
end

ruby_block 'backup-splunk-artifacts' do
  block do
    splunk_home = CernerSplunk.splunk_home(node['platform_family'], node['kernel']['machine'], opposite_package_name)
    FileUtils.cp_r(::File.join(splunk_home, '/var/lib/splunk/fishbucket'), Chef::Config[:file_cache_path])
    FileUtils.cp(::File.join(splunk_home, '/etc/passwd'), Chef::Config[:file_cache_path])
    node.run_state['cerner_splunk']['splunk_forwarder_migrate'] = true
  end
end

package opposite_package_name do
  package_name CernerSplunk.installed_package_name(node['platform_family'], opposite_package_name)
  action :remove
end

directory CernerSplunk.splunk_home(node['platform_family'], node['kernel']['machine'], opposite_package_name) do
  action :delete
  recursive true
end
