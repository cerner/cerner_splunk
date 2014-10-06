# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_alerts
#
# Configures the alert settings for the system

hash = CernerSplunk::DataBag.load node[:splunk][:config][:alerts], pick_context: CernerSplunk.keys(node)

unless hash
  Chef::Log.info 'Splunk Alerts not configured for this node.'
  return
end

hash = hash.clone
default_coords = CernerSplunk::DataBag.to_a node[:splunk][:config][:alerts]
bag = CernerSplunk::DataBag.load hash.delete('bag'), default: default_coords

alert_stanzas =
  if bag
    bag.merge(hash) do |_key, default_hash, override_hash|
      default_hash.merge(override_hash)
    end
  else
    hash
  end

fail 'Unexpected property \'bag\'' if alert_stanzas.delete('bag')

email_settings = alert_stanzas['email'] || {}

if email_settings['auth_password']
  password = CernerSplunk::DataBag.load email_settings['auth_password'], default: default_coords, type: :vault
  fail 'Password must be a String' unless password.is_a?(String)
  email_settings['auth_password'] = password
end

splunk_template 'system/alert_actions.conf' do
  stanzas alert_stanzas
  notifies :restart, 'service[splunk]'
end
