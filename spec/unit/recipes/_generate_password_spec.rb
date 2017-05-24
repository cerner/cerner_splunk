
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_generate_password' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['node_type'] = node_type
      node.override['splunk']['home'] = '/opt/splunk'
      node.override['splunk']['cmd'] = '/opt/splunk/bin/splunk'
      node.override['splunk']['config']['password_secrets'] = password_secrets
      chef_run_stubs
    end
    runner.converge(described_recipe)
  end

  let(:platform) { 'redhat' }
  let(:platform_version) { '7.2' }
  let(:node_type) { :server }
  let(:system_user) { 'root' }
  let(:system_group) { system_user }

  let(:password_secrets) { { 'server' => 'cerner_splunk/admin_password:admin_password' } }
  let(:vault_exists) { true }
  let(:vault_item) { { 'admin_password' => 'vaultpassword' } }

  let(:password_hashes) do
    require 'unix_crypt'
    {
      'vaultpassword' => "admin:#{UnixCrypt::SHA256.build('vaultpassword')}::Administrator:admin:changeme@example.com::",
      'filepassword' => "admin:#{UnixCrypt::SHA256.build('filepassword')}::Administrator:admin:changeme@example.com::",
      'changeme' => "admin:#{UnixCrypt::SHA256.build('changeme')}::Administrator:admin:changeme@example.com::",
      'bogus' => "admin:#{UnixCrypt::SHA256.build('bogus')}::Administrator:admin:changeme@example.com::"
    }
  end
  let(:current_password) {}

  let(:chef_run_stubs) do
    if vault_item
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'admin_password').and_return(vault_item)
    else
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'admin_password').and_raise(ChefVault::Exceptions::ItemNotFound)
    end

    expect(SecureRandom).to receive(:hex).with(36).and_return('randompassword')

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist).with('/opt/splunk/etc/passwd').and_return(true)
    allow(File).to receive(:read).with('/opt/splunk/etc/passwd').and_return(password_hashes[current_password])

    contextual_stubs
  end

  let(:contextual_stubs) {}

  shared_examples 'changing password' do
    let(:execute_params) do
      {
        command: "/opt/splunk/bin/splunk edit user admin -password randompassword -roles admin -auth admin:#{current_password}",
        environment: { 'HOME' => '/opt/splunk' },
        sensitive: true
      }
    end
    it { is_expected.to run_execute('Update admin password').with execute_params }
  end

  context 'when the vault item is configured for the current node' do
    shared_examples 'updating vault' do
      it { is_expected.to run_ruby_block('update admin password in vault item') }
    end

    let(:contextual_stubs) do
      expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
      expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
    end
    let(:current_password) { 'vaultpassword' }

    include_examples 'changing password'
    include_examples 'updating vault'

    context 'when the current password is the file password' do
      let(:vault_item) { {} }
      let(:current_password) { 'filepassword' }
      let(:contextual_stubs) do
        expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
        expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
      end

      include_examples 'changing password'
      include_examples 'updating vault'

      context 'when the current password is the default password' do
        let(:current_password) { 'changeme' }

        include_examples 'changing password'
        include_examples 'updating vault'

        context 'when the current password does not match any provided passwords' do
          let(:contextual_stubs) {}
          let(:current_password) { 'bogus' }

          it 'fails the chef run' do
            expect { subject }.to raise_error('Vault item for admin password was configured, but the item does not exist')
          end
        end
      end
    end

    context 'when the vault password does not exist' do
      let(:vault_item) { {} }
      let(:current_password) { 'filepassword' }
      let(:contextual_stubs) do
        expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
        expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
      end

      include_examples 'changing password'
      include_examples 'updating vault'

      context 'when the password file does not exist' do
        let(:current_password) { 'changeme' }
        let(:contextual_stubs) do
          expect(File).to receive(:exist?).with('/etc/splunk/password').and_return false
          expect(File).not_to receive(:read).with('/etc/splunk/password')
        end

        include_examples 'changing password'
        include_examples 'updating vault'
      end
    end

    context 'when the vault item does not exist' do
      let(:contextual_stubs) {}
      let(:password_secrets) { { 'server' => 'cerner_splunk/admin_password:admin_password' } }
      let(:vault_item) {}

      it 'fails the chef run' do
        expect { subject }.to raise_error('Vault item for admin password was configured, but the item does not exist')
      end
    end
  end

  context 'when the vault item is not configured for the current node' do
    shared_examples 'updating file' do
      let(:expected_params) do
        {
          backup: false,
          sensitive: true,
          owner: system_user,
          group: system_group,
          mode: '0600',
          content: 'randompassword'
        }
      end
      it { is_expected.to create_file('/etc/splunk/password').with expected_params }
    end

    let(:password_secrets) { { 'anotherserver' => 'cerner_splunk/admin_password:admin_password' } }
    let(:vault_item) {}
    let(:current_password) { 'filepassword' }
    let(:contextual_stubs) do
      expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
      expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
    end

    include_examples 'changing password'
    include_examples 'updating file'

    context 'when the current password is the default password' do
      let(:current_password) { 'changeme' }

      include_examples 'changing password'
      include_examples 'updating file'
    end

    context 'when the password file does not exist' do
      let(:current_password) { 'changeme' }
      let(:contextual_stubs) do
        expect(File).to receive(:exist?).with('/etc/splunk/password').and_return false
        expect(File).not_to receive(:read).with('/etc/splunk/password')
      end

      include_examples 'changing password'
      include_examples 'updating file'
    end

    shared_examples_for 'search head cluster member without vault item' do
      it 'fails the chef run' do
        expect { subject }.to raise_error("You must configure a vault item for this search head cluster's admin password")
      end
    end

    context 'when the node is a search head cluster member' do
      let(:contextual_stubs) {}
      it_should_behave_like 'search head cluster member without vault item' do
        let(:node_type) { :shc_search_head }
      end
    end

    context 'when the node is a search head cluster captain' do
      let(:contextual_stubs) {}
      it_should_behave_like 'search head cluster member without vault item' do
        let(:node_type) { :shc_captain }
      end
    end
  end
end
