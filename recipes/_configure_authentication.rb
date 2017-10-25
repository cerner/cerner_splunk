# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_authentication
#
# Configures the roles available on the system

hash = CernerSplunk::DataBag.load node['splunk']['config']['authentication'],
                                  pick_context: CernerSplunk.keys(node),
                                  secret: node['splunk']['data_bag_secret']

unless hash
  Chef::Log.info 'Splunk Authentication not configured for this node.'
  return
end

auth_stanzas = CernerSplunk::Authentication.configure_authentication(node, hash)

splunk_template 'system/authentication.conf' do
  sensitive(auth_stanzas.any? { |_, v| v.key? 'bindDNpassword' })
  stanzas auth_stanzas
  notifies :touch, 'file[splunk-marker]', :immediately
end
