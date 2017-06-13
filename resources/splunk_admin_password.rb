
# frozen_string_literal: true

#
# Cookbook Name:: cerner_splunk
# Resource:: splunk_admin_password
#

resource_name :splunk_admin_password

property :vault_bag, String
property :vault_item, String
property :password_file_path, String

default_action :regenerate

load_current_value do
  node.run_state['cerner_splunk'] ||= {}

  if vault_bag && !vault_item || !vault_bag && vault_item
    raise 'vault_bag and vault_item must both be provided to configure the password vault'
  end
end

action_class do
  def vault
    return unless vault_bag && vault_item
    @vault ||= ChefVault::Item.load(vault_bag, vault_item)
  rescue ChefVault::Exceptions::KeysNotFound, ChefVault::Exceptions::ItemNotFound => e
    raise e, 'Vault item for admin password does not exist'
  end

  def load_password_from_vault
    return unless vault_bag && vault_item
    vault['admin_password']
  end

  def load_password_from_file
    return unless password_file_path && ::File.exist?(password_file_path)
    ::File.read(password_file_path)
  end
end

action :regenerate do
  # Generate a new random password.
  require 'securerandom'
  new_password = SecureRandom.hex(36)

  # Load the current password
  require 'unix_crypt'

  passwd_path = Pathname.new(node['splunk']['home']).join('etc/passwd').to_s
  passwd_hash = ::File.read(passwd_path).match(/^:admin:(\$.+?\$.+?\$.+?):.+$/)[1]

  current_password = nil
  %i[vault file default].each do |type|
    possible_password = case type
                        when :vault then load_password_from_vault || next
                        when :file then load_password_from_file || next
                        else 'changeme'
                        end

    # Compare each of the available admin passwords to the passwd hash.
    # We want to determine that our password is valid before trying to use it.
    next unless possible_password.is_a?(String) && UnixCrypt.valid?(possible_password, passwd_hash)
    current_password = possible_password
    break
  end
  raise 'Could not determine a valid admin password' unless current_password

  node.run_state['cerner_splunk']['admin_password'] = current_password

  # Change the password in splunk to the new random password
  execute 'update admin password in splunk' do # ~FC009
    command "#{node['splunk']['cmd']} edit user admin -password #{new_password} -roles admin -auth admin:#{current_password}"
    environment 'HOME' => node['splunk']['home']
    sensitive true
  end

  node.run_state['cerner_splunk']['admin_password'] = new_password

  # Store the random password in a vault, if configured
  if vault
    vault['admin_password'] = new_password
    vault.save
  end

  system_user = system_group = platform_family?('windows') ? 'SYSTEM' : 'root'

  # Store the random password in a file, if a vault is not configured
  file password_file_path do
    backup false
    sensitive true
    if vault
      action :delete
    else
      owner system_user
      group system_group
      mode '0600'
      content new_password
    end
  end
end
