# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_ui
#
# Configures the ui settings for the system

splunk_conf 'system/ui-prefs.conf' do
  config node['splunk']['config']['ui_prefs']
  action :configure
  notifies :ensure, "splunk_restart[#{node['splunk']['package']['type']}]", :immediately
end
