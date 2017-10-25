# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_roles
#
# Configures the roles available on the search heads in a search head cluster

hash = CernerSplunk::DataBag.load node['splunk']['config']['roles'],
                                  pick_context: ['shcluster'],
                                  secret: node['splunk']['data_bag_secret']

unless hash
  Chef::Log.info 'Roles not configured for the search heads in the search head cluster.'
  return
end

authorize, user_prefs = CernerSplunk::Roles.configure_roles(hash)

authorize_action = authorize.empty? ? :delete : :create

splunk_template 'shcluster/_shcluster/authorize.conf' do
  stanzas authorize
  action authorize_action
  notifies :run, 'execute[apply-shcluster-bundle]'
end

user_prefs_action = user_prefs.empty? ? :delete : :create

splunk_template 'shcluster/_shcluster/user-prefs.conf' do
  stanzas user_prefs
  action user_prefs_action
  notifies :run, 'execute[apply-shcluster-bundle]'
end
