# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _install
#
# Performs the installation of the Splunk software via package.

include_recipe 'chef-vault::default'

include_recipe 'cerner_splunk::_cleanup_aeon'

# Interpolation Alias
def nsp
  node['splunk']['package']
end

# Attributes
node.default['splunk']['package']['name'] = "#{nsp['base_name']}-#{nsp['version']}-#{nsp['build']}"
node.default['splunk']['package']['file_name'] = "#{nsp['name']}#{nsp['file_suffix']}"
node.default['splunk']['package']['url'] =
  "#{nsp['base_url']}/#{nsp['version']}/#{nsp['download_group']}/#{nsp['platform']}/#{nsp['file_name']}"

if platform_family?('windows')
  if node['kernel']['machine'] == 'x86_64'
    node.default['splunk']['home'] = "#{ENV['PROGRAMW6432'].tr('\\', '/')}/#{nsp['base_name']}"
  else
    node.default['splunk']['home'] = "#{ENV['PROGRAMFILES'].tr('\\', '/')}/#{nsp['base_name']}"
  end
  # The translate is intended to switch the direction of slashes to be windows friendly,
  # the second replacement surrounds any file names with spaces in quotes
  node.default['splunk']['cmd'] = "#{node['splunk']['home']}/bin/splunk".tr('/', '\\').gsub(/\w+\s\w+/) { |directory| %("#{directory}") }
  service = 'SplunkForwarder'
else
  node.default['splunk']['home'] = "/opt/#{nsp['base_name']}"
  node.default['splunk']['cmd'] = "#{node['splunk']['home']}/bin/splunk"
  service = 'splunk'
end

manifest_missing = proc { ::Dir.glob("#{node['splunk']['home']}/#{node['splunk']['package']['name']}-*").empty? }

# Actions
file 'splunk-marker' do
  action :nothing
  backup false
  path CernerSplunk.restart_marker_file
end

file 'splunk-seed' do
  action :nothing
  path "#{node['splunk']['home']}/old_splunk.seed"
  content node['splunk']['cleanup_path']
  backup false
  owner node['splunk']['user']
  group node['splunk']['group']
  mode '0600'
end

# This service definition is used only for ensuring splunk is started during the run
service 'splunk-start' do
  service_name service
  action :nothing
  supports status: true, start: true
  notifies :delete, 'file[splunk-marker]', :immediately
end

# This service definition is used for restarting splunk when the run is over
service 'splunk' do
  service_name service
  action :nothing
  supports status: true, restart: true
  only_if { ::File.exist? CernerSplunk.restart_marker_file }
  notifies :delete, 'file[splunk-marker]', :immediately
end

ruby_block 'splunk-delayed-restart' do
  block { true }
  notifies :restart, 'service[splunk]'
end

splunk_file = "#{Chef::Config[:file_cache_path]}/#{node['splunk']['package']['file_name']}"

remote_file splunk_file do
  source node['splunk']['package']['url']
  action :create
  only_if(&manifest_missing)
end

package node['splunk']['package']['base_name'] do
  source splunk_file
  version "#{node['splunk']['package']['version']}-#{node['splunk']['package']['build']}"
  provider node['splunk']['package']['provider']
  only_if(&manifest_missing)
  if node['splunk']['cleanup_path']
    # Instruct splunk to seed the fishbucket from a previous installation
    notifies :create, 'file[splunk-seed]', :immediately
  end
  if platform_family?('windows')
    # installing as the system user by default as Splunk has difficulties with being a limited user
    options %(AGREETOLICENSE=Yes SERVICESTARTTYPE=auto LAUNCHSPLUNK=0 INSTALLDIR="#{node['splunk']['home'].tr('/', '\\')}")
  else
    notifies :run, 'execute[splunk-first-run]', :immediately
  end
end

directory node['splunk']['external_config_directory'] do
  owner node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

# SPL-89640 On upgrades, the permissions of this directory is too restrictive
# preventing proper operation of Platform Instrumentation features.
directory "#{node['splunk']['home']}/var/log/introspection" do
  owner node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

file 'splunk_package' do
  path splunk_file
  backup false
  not_if(&manifest_missing)
  action :delete
end

include_recipe 'cerner_splunk::_user_management'

execute 'splunk-first-run' do
  command "#{node['splunk']['cmd']} help commands --accept-license --answer-yes --no-prompt"
  user node['splunk']['user']
  group node['splunk']['group']
  action :nothing
end

# This gets rid of the change password prompt on first login
file "#{node['splunk']['home']}/etc/.ui_login" do
  action :touch
  not_if { ::File.exist? "#{node['splunk']['home']}/etc/.ui_login" }
end

# System file changes should be done after first run, but before we start the server
include_recipe 'cerner_splunk::_configure'
