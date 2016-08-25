# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_authentication
#
# Configures the authentication available on the system in a search head cluster

hash = CernerSplunk::DataBag.load node['splunk']['config']['authentication'], pick_context: ['shcluster']

unless hash
  Chef::Log.info 'Splunk Authentication not configured for the search heads in the search head cluster.'
  return
end

auth_stanzas = CernerSplunk::Authentication.configure_authentication(node, hash)


splunk_conf 'shcluster/apps/_shcluster/authentication.conf' do
  config CernerSplunk::Alerts.configure_alerts(node, hash)
  sensitive auth_stanzas.any? { |_, v| v.key? 'bindDNpassword' }
  notifies :run, 'execute[apply-shcluster-bundle]'
  action :configure
end
