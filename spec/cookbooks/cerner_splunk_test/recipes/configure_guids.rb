# coding: UTF-8

# Cookbook Name:: cerner_splunk_test
# Recipe:: configure_guids
#
# Configures the GUIDS for cluster slaves.

guid_c1_slave1 = 'aae84706-a70d-4134-951d-93a6541011fa'
guid_c1_slave2 = '9d8f6bb8-49b2-463e-afdd-aedf267526e4'
guid_c1_slave3 = '3da644f5-6750-4d07-b158-0cf42c8a6153'

path = "#{node['splunk']['home']}/etc/instance.cfg"

guid =
  case node['hostname']
  when 'slave01'
    guid_c1_slave1
  when 'slave02'
    guid_c1_slave2
  when 'slave03'
    guid_c1_slave3
  end

template path do
  source 'instance.cfg.erb'
  variables guid: guid
  notifies :touch, 'file[splunk-marker]', :immediately
end
