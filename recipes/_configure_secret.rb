# coding: UTF-8

# Cookbook Name:: cerner_splunk
# Recipe:: _configure_secret
#
# Configures the system splunk.secret file

secrets_hash = node['splunk']['config']['secrets']
key = CernerSplunk.keys(node).find { |x| secrets_hash.key?(x.to_s) } if secrets_hash

# We can't keep windows from quasi-starting on package install and we don't
# yet allow changing the secret file once it exists so don't set it for windows.
if !key || platform_family?('windows')
  Chef::Log.info 'Splunk Secrets either not configured for this node or the node is windows where secrets are not supported.'
  return
end

secret = CernerSplunk::DataBag.load secrets_hash[key], secret: node['splunk']['data_bag_secret'], handle_load_failure: true
fail 'Configured splunk secret must resolve to a String' unless secret.is_a?(String)

secret_path = ::File.join(node['splunk']['home'], 'etc', 'auth', 'splunk.secret')

ruby_block 'Check splunk.secret file' do
  block do
    CernerSplunk.validate_secret_file(secret_path, secret)
  end
end

file 'splunk.secret' do
  backup false
  path secret_path
  user node['splunk']['user']
  group node['splunk']['group']
  mode '0400'
  content "#{secret}\n"
  sensitive true
end
