# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_ui
#
# Configures the ui settings for the system

splunk_template 'system/ui-prefs.conf' do
  stanzas node['splunk']['config']['ui_prefs']
  notifies :touch, 'file[splunk-marker]', :immediately
end
