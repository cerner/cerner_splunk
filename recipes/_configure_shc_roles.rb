
# frozen_string_literal: true

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

splunk_conf 'shcluster/apps/_shcluster/authorize.conf' do
  action authorize.empty? ? :delete : :configure
  config authorize
  notifies :run, 'execute[apply-shcluster-bundle]'
end

splunk_conf 'shcluster/apps/_shcluster/user-prefs.conf' do
  action user_prefs.empty? ? :delete : :configure
  config user_prefs
  notifies :run, 'execute[apply-shcluster-bundle]'
end
