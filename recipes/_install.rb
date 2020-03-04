# frozen_string_literal: true

# Cookbook Name:: cerner_splunk
# Recipe:: _install
#
# Performs the installation of the Splunk software via package.

# Interpolation Alias
def nsp
  node['splunk']['package']
end

# Attributes
node.default['splunk']['package']['name'] = "#{nsp['base_name']}-#{nsp['version']}-#{nsp['build']}"
node.default['splunk']['package']['file_name'] = "#{nsp['name']}#{nsp['file_suffix']}"
node.default['splunk']['package']['url'] =
  "#{nsp['base_url']}/#{nsp['download_group']}/releases/#{nsp['version']}/#{nsp['platform']}/#{nsp['file_name']}"
node.default['splunk']['home'] = CernerSplunk.splunk_home(node['platform_family'], node['kernel']['machine'], nsp['base_name'])
node.default['splunk']['cmd'] = CernerSplunk.splunk_command(node)

service = CernerSplunk.splunk_service_name(node['platform_family'], nsp['base_name'])

manifest_missing = proc { ::Dir.glob("#{node['splunk']['home']}/#{node['splunk']['package']['name']}-*").empty? }

include_recipe 'cerner_splunk::_restart_marker'

# Under systemd, starting or restarting the service allows the chef run to continue
# before Splunk is finished initializing.  Need to wait a bit to let it fully start
# before we run any other commands.
execute 'sleep-10' do
  command 'sleep 10'
  action :nothing
  only_if { ::File.exist? node['splunk']['systemd_file_location'] }
end

# Actions
# This service definition is used for ensuring splunk is started during the run and to stop splunk service
service 'splunk' do
  service_name service
  action :nothing
  supports status: true, start: true, stop: true
  notifies :delete, 'file[splunk-marker]', :immediately
  notifies :run, 'execute[sleep-10]', :immediately
end

# This service definition is used for restarting splunk when the run is over
service 'splunk-restart' do
  service_name service
  action :nothing
  supports status: true, restart: true
  only_if { ::File.exist? CernerSplunk.restart_marker_file }
  notifies :delete, 'file[splunk-marker]', :immediately
  notifies :run, 'execute[sleep-10]', :immediately
end

ruby_block 'splunk-delayed-restart' do
  block { true }
  notifies :restart, 'service[splunk-restart]'
end

splunk_file = "#{Chef::Config[:file_cache_path]}/#{node['splunk']['package']['file_name']}"

remote_file splunk_file do
  source node['splunk']['package']['url']
  action :create
  only_if(&manifest_missing)
end

if platform_family? 'rhel', 'fedora', 'amazon'
  rpm_package node['splunk']['package']['base_name'] do
    source splunk_file
    version "#{node['splunk']['package']['version']}-#{node['splunk']['package']['build']}"
    only_if(&manifest_missing)
  end
elsif platform_family? 'debian'
  dpkg_package node['splunk']['package']['base_name'] do
    source splunk_file
    version "#{node['splunk']['package']['version']}-#{node['splunk']['package']['build']}"
    only_if(&manifest_missing)
  end
elsif platform_family? 'windows'
  # installing as the system user by default as Splunk has difficulties with being a limited user
  flags = %(AGREETOLICENSE=Yes SERVICESTARTTYPE=auto LAUNCHSPLUNK=0 INSTALLDIR="#{node['splunk']['home'].tr('/', '\\')}")
  # TODO: Use admin_password from databag for splunk-first-run.
  flags += ' SPLUNKPASSWORD=changeme' if Gem::Version.new(nsp['version']) >= Gem::Version.new('7.1.0')
  windows_package node['splunk']['package']['base_name'] do
    source splunk_file
    version "#{node['splunk']['package']['version']}-#{node['splunk']['package']['build']}"
    only_if(&manifest_missing)
    options flags
  end
else
  fail 'unsupported platform'
end

include_recipe 'cerner_splunk::_configure_secret'

run_command = "#{node['splunk']['cmd']} help commands --accept-license --answer-yes --no-prompt"
# TODO: Use admin_password from databag for splunk-first-run.
run_command += " --seed-passwd 'changeme'" if Gem::Version.new(nsp['version']) >= Gem::Version.new('7.2.0')

# For windows, we accept the license during msi install so the ftr file will never be there.
unless platform_family?('windows')
  execute 'splunk-first-run' do
    command run_command
    user node['splunk']['user']
    group node['splunk']['group']
    only_if { File.exist?("#{node['splunk']['home']}/ftr") }
  end
end

ruby_block 'read splunk.secret' do
  block do
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

# This gets rid of the change password prompt on first login
file "#{node['splunk']['home']}/etc/.ui_login" do
  action :touch
  not_if { ::File.exist? "#{node['splunk']['home']}/etc/.ui_login" }
end

# System file changes should be done after first run, but before we start the server
include_recipe 'cerner_splunk::_configure'
