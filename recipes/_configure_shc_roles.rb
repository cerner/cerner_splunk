# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# Recipe:: _configure_shc_roles
#
# Configures the roles available on the search heads in a search head cluster

hash = CernerSplunk::DataBag.load node['splunk']['config']['roles'],
                                  pick_context: ['shcluster']

unless hash
  Chef::Log.info 'Roles not configured for the search heads in the search head cluster.'
  return
end

authorize, user_prefs = CernerSplunk::Roles.configure_roles(hash)

authorize_action = authorize.empty? ? :delete : :configure

splunk_conf 'shcluster/apps/_shcluster/authorize.conf' do
  config authorize
  notifies :run, 'execute[apply-shcluster-bundle]'
  action :configure
end

user_prefs_action = user_prefs.empty? ? :delete : :configure

splunk_conf 'shcluster/apps/_shcluster/user-prefs.conf' do
  config user_prefs
  notifies :run, 'execute[apply-shcluster-bundle]'
  action :configure
end