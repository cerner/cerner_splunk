
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _install
#
# Performs the installation of the Splunk software via package.

include_recipe 'chef-vault::default'

# Interpolation Alias
def nsp
  node['splunk']['package']
end

# Attributes
node.default['splunk']['package']['type'] = CernerSplunk.package_type(nsp['base_name'])
node.default['splunk']['home'] = CernerSplunk::PathHelpers.cerner_default_install_dirs.dig(nsp['type'].to_sym, node['os'].to_sym)
node.default['splunk']['cmd'] = CernerSplunk.splunk_command(node)

splunk_install 'splunk' do
  package node['splunk']['package']['type'].to_sym
  version node['splunk']['package']['version']
  build node['splunk']['package']['build']
  user node['splunk']['user']
  base_url node['splunk']['package']['base_url']
end

include_recipe 'cerner_splunk::_configure_secret'

splunk_service node['splunk']['package']['type'] do
  package node['splunk']['package']['type'].to_sym
  ulimit node['splunk']['limits']['open_files'].to_i unless node['platform_family'] == 'windows'
  action :init
end

# The above initialization does not handle creating splunk.secret and encrypted config.
# This is an unexpected behavior of the Splunk CLI, as the command used there does not call
# splunkd (which automatically creates secrets).
execute 'finish splunk setup' do
  command "#{node['splunk']['cmd']} help commands"
  sensitive true # The output of this is long and useless
end

ruby_block 'read splunk.secret' do
  block do
    node.run_state['cerner_splunk'] ||= {}
    node.run_state['cerner_splunk']['splunk.secret'] = ::File.open(::File.join(node['splunk']['home'], 'etc/auth/splunk.secret'), 'r') { |file| file.readline.chomp }
  end
end

directory node['splunk']['external_config_directory'] do
  owner node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

# SPL-89640 On upgrades, the permissions of this directory is too restrictive
# preventing proper operation of Platform Instrumentation features.
# Check to make sure this is still an issue: http://docs.splunk.com/Documentation/Splunk/latest/Releasenotes/Knownissues
directory "#{node['splunk']['home']}/var/log/introspection" do
  owner node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

include_recipe 'cerner_splunk::_user_management'

# This gets rid of the change password prompt on first login
file "#{node['splunk']['home']}/etc/.ui_login" do
  action :touch
  not_if { ::File.exist? "#{node['splunk']['home']}/etc/.ui_login" }
end

# System file changes should be done after first run, but before we start the server
include_recipe 'cerner_splunk::_configure'
