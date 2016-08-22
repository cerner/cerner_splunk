# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_roles
#
# Configures the roles available on the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['roles'],
                                  pick_context: CernerSplunk.keys(node)

unless hash
  Chef::Log.info 'Roles not configured for this node.'
  return
end

authorize, user_prefs = CernerSplunk::Roles.configure_roles(hash)

authorize_action = authorize.empty? ? :configure : :configure

splunk_conf 'system/authorize.conf' do
  path 'system/authorize.conf'
  config authorize
  action authorize_action
end

directory "#{node['splunk']['home']}/etc/apps/user-prefs/local" do
  user node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

user_prefs_action = user_prefs.empty? ? :configure : :configure

splunk_conf 'apps/user-prefs/user-prefs.conf' do
  path 'apps/user-prefs/user-prefs.conf' 
  config user_prefs
  action user_prefs_action
end
