# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_alerts
#
# Configures the alert settings for the search heads in a search head cluster

hash = CernerSplunk::DataBag.load node['splunk']['config']['alerts'], pick_context: ['shcluster']

unless hash
  Chef::Log.info 'Splunk Alerts not configured for the search heads in the search head cluster.'
  return
end

splunk_conf 'shcluster/apps/_shcluster/alert_actions.conf' do
  config CernerSplunk::Alerts.configure_alerts(node, hash)
  action :configure
  notifies :run, 'execute[apply-shcluster-bundle]'
end

