# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_user_seed.rb
#
# Configures the system inputs.conf file

# Translate monitor attributes to generic hash
input_stanzas = {}
input_stanzas['user_info'] = {}
input_stanzas['user_info']['USERNAME'] = 'admin'
input_stanzas['user_info']['PASSWORD'] = 'changeme'

splunk_template 'system/user-seed.conf' do
  stanzas input_stanzas
  notifies :touch, 'file[splunk-marker]', :immediately
end