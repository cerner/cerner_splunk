
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _generate_password
#
# Generates and sets a random password for the admin splunk account.
# This recipe must be run while Splunk is running.

return if node['splunk']['free_license'] && node['splunk']['node_type'] != :forwarder

# Generate a new random password.
require 'securerandom'
new_password = SecureRandom.hex(36)

# Identify the most specific vault path that matches the current node name and type.
password_vault_paths = node['splunk']['config']['password_secrets'] || {}
vault_path = (password_vault_paths.find { |k, _| CernerSplunk.keys(node).include? k } || []).last
vault_bag, vault_item = CernerSplunk::DataBag.to_a(vault_path)

# If a password vault is configured, retrieve the admin password
if vault_path
  begin
    vault = ChefVault::Item.load(vault_bag, vault_item)
    vault_password = vault.dig('admin_password')
  rescue ChefVault::Exceptions::KeysNotFound, ChefVault::Exceptions::ItemNotFound => e
    raise e, 'Vault item for admin password was configured, but the item does not exist'
  end
elsif %i[shc_search_head shc_captain].include? node['splunk']['node_type']
  raise "You must configure a vault item for this search head cluster's admin password"
end

# If a password file exists, retrieve the admin password (lazy so we don't read the file if the vault is valid)
def password_file_path
  Pathname.new(node['splunk']['external_config_directory']).join('password').to_s
end

def file_password
  File.read(password_file_path) if File.exist?(password_file_path)
end

# Compare each of the available admin passwords to the passwd hash.
# We want to determine that our password is valid before trying to use it.
require 'unix_crypt'
passwd_path = Pathname.new(node['splunk']['home']).join('etc/passwd').to_s
if File.exist? passwd_path
  passwd_hash = File.read(passwd_path).match(/^:admin:(\$.+?\$.+?\$.+?):.+$/)[1]
  old_password = [vault_password, file_password, 'changeme'].find { |pw| pw && pw.is_a?(String) && UnixCrypt.valid?(pw, passwd_hash) }
  raise 'Could not determine a valid admin password' unless old_password
else
  old_password = 'changeme'
end

(node.run_state['cerner_splunk'] ||= {})['admin_password'] = old_password

execute 'update admin password in splunk' do # ~FC009
  command "#{node['splunk']['cmd']} edit user admin -password #{new_password} -roles admin -auth admin:#{old_password}"
  environment 'HOME' => node['splunk']['home']
  sensitive true
end

ruby_block 'update admin password in run_state' do
  block do
    node.run_state['cerner_splunk']['admin_password'] = new_password
  end
end

ruby_block 'update admin password in vault item' do
  block do
    vault['admin_password'] = new_password
    vault.save
  end
  only_if { vault_path.is_a? String }
end

system_user = system_group = platform_family?('windows') ? 'SYSTEM' : 'root'

file password_file_path do
  backup false
  sensitive true
  if vault_path
    action :delete
  else
    owner system_user
    group system_group
    mode '0600'
    content new_password
  end
end
