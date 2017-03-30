
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: image_prep
#
# Make a universal forwarder part of a host image.
#
# Requires Chef 12.6.0 or above
#
# See http://docs.splunk.com/Documentation/Forwarder/6.5.2/Forwarder/Makeauniversalforwarderpartofahostimage

execute 'clone-prep-clear-config' do
  command "#{node['splunk']['cmd']} clone-prep-clear-config"
  user node['splunk']['user']
  group node['splunk']['group']
  notifies :stop, 'service[splunk]', :before
  notifies :delete, 'file[splunk-marker]', :before
  # TODO: Replace with splunk_restart
end
