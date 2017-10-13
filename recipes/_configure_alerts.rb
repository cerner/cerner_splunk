# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_alerts
#
# Configures the alert settings for the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['alerts'],
                                  pick_context: CernerSplunk.keys(node),
                                  secret: node['splunk']['data_bag_secret']

unless hash
  Chef::Log.info 'Splunk Alerts not configured for this node.'
  return
end

splunk_template 'system/alert_actions.conf' do
  stanzas CernerSplunk::Alerts.configure_alerts(node, hash)
  notifies :touch, 'file[splunk-marker]', :immediately
end
