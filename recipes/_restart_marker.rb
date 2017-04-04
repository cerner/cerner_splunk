# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _restart_marker
#
# Creates the restart file marker. This is used to ensure that the service is only restarted once and that it
# only restarts when needed

file 'splunk-marker' do
  action :nothing
  backup false
  path CernerSplunk.restart_marker_file
end
