# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _cleanup_forwarder
#
# Cleans up old forwarder install if switching between UF and HWF

if node['splunk']['node_type'] == :forwarder
  old_package_name = 'splunk'
  old_splunk_home = '/opt/splunk'
else
  old_package_name = 'splunkforwarder'
  old_splunk_home = '/opt/splunkforwarder'
end

package 'old-splunk-package' do
  action :nothing
  package_name old_package_name
end

directory 'old-splunk-home' do
  action :nothing
  path old_splunk_home
  recursive true
end

if File.exist?(old_splunk_home)
  node.default['splunk']['cleanup_path'] = old_splunk_home

  # Stop service but delay removal until after migration
  service 'splunk' do
    action :stop
    notifies :remove, 'package[old-splunk-package]'
    notifies :delete, 'directory[old-splunk-home]'
  end
end
