
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Recipe:: _generate_password
#
# Generates and sets a random password for the admin splunk account.
# This recipe must be run while Splunk is running.

return if node['splunk']['free_license'] && node['splunk']['node_type'] != :forwarder

# Identify the most specific vault path that matches the current node name and type.
password_vault_paths = node['splunk']['config']['password_secrets'] || {}
vault_path = (password_vault_paths.find { |k, _| CernerSplunk.keys(node).include? k } || []).last
vault_bag, vault_item = CernerSplunk::DataBag.to_a(vault_path)
if %i[shc_search_head shc_captain].include? node['splunk']['node_type']
  raise "You must configure a vault item for this search head cluster's admin password" unless vault_bag && vault_item
end

# If a password file exists, retrieve the admin password (lazy so we don't read the file if the vault is valid)
password_file_path = Pathname.new(node['splunk']['external_config_directory']).join('password').to_s

splunk_admin_password 'change the splunk admin password' do
  vault_bag vault_bag
  vault_item vault_item
  password_file_path password_file_path
end
