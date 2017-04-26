
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _migrate_forwarder
#
# Migrates from the Universal Forwarder to a heavy forwarder

require 'fileutils'

opposite_package_name = CernerSplunk.opposite_package_name(node['splunk']['package']['base_name'])
old_package_type = CernerSplunk.package_type(opposite_package_name).to_sym

splunk_service 'stop old service' do
  package old_package_type
  action :stop
end

ruby_block 'backup-splunk-artifacts' do
  block do
    splunk_home = CernerSplunk::PathHelpers.cerner_default_install_dirs.dig(old_package_type, node['os'].to_sym)
    FileUtils.cp_r(::File.join(splunk_home, '/var/lib/splunk/fishbucket'), Chef::Config[:file_cache_path])
    FileUtils.cp(::File.join(splunk_home, '/etc/passwd'), Chef::Config[:file_cache_path])
    node.run_state['cerner_splunk']['splunk_forwarder_migrate'] = true
  end
end

splunk_install 'uninstall old splunk' do
  package old_package_type
  action :uninstall
end
