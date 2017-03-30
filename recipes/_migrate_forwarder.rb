
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _migrate_forwarder
#
# Migrates from the Universal Forwarder to a heavy forwarder

require 'fileutils'

opposite_package_name = CernerSplunk.opposite_package_name(node['splunk']['package']['base_name'])
old_package =
  case opposite_package_name # TODO: Let's DRY up this bit
  when 'splunk' then :splunk
  when 'splunkforwarder' then :universal_forwarder
  end

splunk_service 'stop old service' do
  package old_package
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

splunk_install 'uninstall old splunk' do
  package old_package
  action :uninstall
end

# TODO: What is this

# package opposite_package_name do
#   package_name CernerSplunk.installed_package_name(node['platform_family'], opposite_package_name)
#   action :remove
# end

# directory CernerSplunk.splunk_home(node['platform_family'], node['kernel']['machine'], opposite_package_name) do
#   action :delete
#   recursive true
# end
