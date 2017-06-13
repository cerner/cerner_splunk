
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_authentication
#
# Configures the roles available on the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['authentication'], pick_context: CernerSplunk.keys(node)

unless hash
  Chef::Log.info 'Splunk Authentication not configured for this node.'
  return
end

auth_stanzas = CernerSplunk::Authentication.configure_authentication(node, hash)

splunk_conf 'system/authentication.conf' do
  config auth_stanzas
  sensitive(auth_stanzas.any? { |_, v| v.key? 'bindDNpassword' })
  action :configure
  notifies :desired_restart, "splunk_service[#{node['splunk']['package']['type']}]", :immediately
end
