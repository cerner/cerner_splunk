# coding: UTF-8

# Cookbook Name:: cerner_splunk_test
# Recipe:: _splunk_service
#
# Sets up the basic splunk service resources.

include_recipe 'cerner_splunk::_restart_marker'

def nsp
  node['splunk']['package']
end
service = CernerSplunk.splunk_service_name(node['platform_family'], nsp['base_name'])

# This service definition is used for restarting splunk when the run is over
service 'splunk' do
  service_name service
  action :nothing
  supports status: true, restart: true
  only_if { ::File.exist? CernerSplunk.restart_marker_file }
  notifies :delete, 'file[splunk-marker]', :immediately
end
