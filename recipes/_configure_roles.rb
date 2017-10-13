# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_roles
#
# Configures the roles available on the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['roles'],
                                  pick_context: CernerSplunk.keys(node),
                                  secret: node['splunk']['data_bag_secret']

unless hash
  Chef::Log.info 'Roles not configured for this node.'
  return
end

authorize, user_prefs = CernerSplunk::Roles.configure_roles(hash)

authorize_action = authorize.empty? ? :delete : :create

splunk_template 'system/authorize.conf' do
  stanzas authorize
  action authorize_action
  notifies :touch, 'file[splunk-marker]', :immediately
end

directory "#{node['splunk']['home']}/etc/apps/user-prefs/local" do
  user node['splunk']['user']
  group node['splunk']['group']
  mode '0700'
end

user_prefs_action = user_prefs.empty? ? :delete : :create

splunk_template 'apps/user-prefs/user-prefs.conf' do
  stanzas user_prefs
  action user_prefs_action
  notifies :touch, 'file[splunk-marker]', :immediately
end
