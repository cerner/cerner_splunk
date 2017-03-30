
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_alerts
#
# Configures the alert settings for the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['alerts'], pick_context: CernerSplunk.keys(node)

unless hash
  Chef::Log.info 'Splunk Alerts not configured for this node.'
  return
end

splunk_conf 'system/alert_actions.conf' do
  config CernerSplunk::Alerts.configure_alerts(node, hash)
  action :configure
  notifies :restart, "splunk_service[#{node['splunk']['package']['base_name']}]"
end
