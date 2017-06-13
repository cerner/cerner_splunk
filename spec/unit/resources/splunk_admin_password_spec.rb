
# frozen_string_literal: true

require_relative '../spec_helper'

require 'unix_crypt'
# Doing this in a let causes it to generate hashes for every example, which is redundant and expensive.
password_hashes = {
  'vaultpassword' => ":admin:#{UnixCrypt::SHA256.build('vaultpassword')}::Administrator:admin:changeme@example.com::",
  'filepassword' => ":admin:#{UnixCrypt::SHA256.build('filepassword')}::Administrator:admin:changeme@example.com::",
  'changeme' => ":admin:#{UnixCrypt::SHA256.build('changeme')}::Administrator:admin:changeme@example.com::",
  'bogus' => ":admin:#{UnixCrypt::SHA256.build('bogus')}::Administrator:admin:changeme@example.com::"
}.freeze

describe 'splunk_admin_password' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.8', step_into: 'splunk_admin_password') do |node|
      node.normal['splunk']['home'] = '/opt/splunk'
      node.normal['splunk']['cmd'] = '/opt/splunk/bin/splunk'
      node.normal['test_parameters'] = test_params
      chef_run_stubs
    end
    runner.converge('cerner_splunk_test::splunk_admin_password_test')
  end

  let(:system_user) { 'root' }
  let(:system_group) { system_user }

  let(:vault_exists) { true }
  let(:vault_item) { { 'admin_password' => 'vaultpassword' } }
  let(:vault_mock) { double('vault item') }

  let(:current_password) {}

  let(:chef_run_stubs) do
    if vault_item
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'admin_password').and_return(vault_mock)
    else
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'admin_password').and_raise(ChefVault::Exceptions::ItemNotFound)
    end

    expect(SecureRandom).to receive(:hex).with(36).and_return('randompassword')

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).with('/opt/splunk/etc/passwd').and_return(true)
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
    it { is_expected.to run_execute('update admin password in splunk').with execute_params }
  end

  context 'when the vault item is configured for the current node' do
    shared_examples 'deleting file' do
      let(:expected_params) do
        {
          backup: false,
          sensitive: true
        }
      end
      it { is_expected.to delete_file('/etc/splunk/password').with expected_params }
    end

    let(:contextual_stubs) do
      expect(File).not_to receive(:exist?).with('/etc/splunk/password')
      expect(File).not_to receive(:read).with('/etc/splunk/password')
      expect(vault_mock).to receive(:[]) { |key| vault_item[key] }
      expect(vault_mock).to receive(:[]=).with('admin_password', 'randompassword')
      expect(vault_mock).to receive(:save)
    end
    let(:current_password) { 'vaultpassword' }
    let(:test_params) { { vault_bag: 'cerner_splunk', vault_item: 'admin_password', password_file_path: '/etc/splunk/password' } }

    include_examples 'changing password'
    # Updating vault is tested by expectations in contextual_stubs
    include_examples 'deleting file'

    context 'when the current password is the file password' do
      let(:contextual_stubs) do
        expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
        expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
        expect(vault_mock).to receive(:[]) { |key| vault_item[key] }
        expect(vault_mock).to receive(:[]=).with('admin_password', 'randompassword')
        expect(vault_mock).to receive(:save)
      end
      let(:current_password) { 'filepassword' }

      include_examples 'changing password'
      # Updating vault is tested by expectations in contextual_stubs
      include_examples 'deleting file'

      context 'when the current password is the default password' do
        let(:current_password) { 'changeme' }

        include_examples 'changing password'
        # Updating vault is tested by expectations in contextual_stubs
        include_examples 'deleting file'

        context 'when the current password does not match any provided passwords' do
          let(:contextual_stubs) do
            expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
            expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
            expect(vault_mock).to receive(:[]) { |key| vault_item[key] }
          end
          let(:current_password) { 'bogus' }

          it 'fails the chef run' do
            expect { subject }.to raise_error(RuntimeError, /Could not determine a valid admin password$/)
          end
        end
      end
    end

    context 'when the vault password does not exist' do
      let(:contextual_stubs) do
        expect(File).to receive(:exist?).with('/etc/splunk/password').and_return true
        expect(File).to receive(:read).with('/etc/splunk/password').and_return 'filepassword'
        expect(vault_mock).to receive(:[]) { |key| vault_item[key] }
        expect(vault_mock).to receive(:[]=).with('admin_password', 'randompassword')
        expect(vault_mock).to receive(:save)
      end
      let(:vault_item) { {} }
      let(:current_password) { 'filepassword' }

      include_examples 'changing password'
      # Updating vault is tested by expectations in contextual_stubs
      include_examples 'deleting file'

      context 'when the password file does not exist' do
        let(:current_password) { 'changeme' }
        let(:contextual_stubs) do
          expect(File).to receive(:exist?).with('/etc/splunk/password').and_return false
          expect(File).not_to receive(:read).with('/etc/splunk/password')
          expect(vault_mock).to receive(:[]) { |key| vault_item[key] }
          expect(vault_mock).to receive(:[]=).with('admin_password', 'randompassword')
          expect(vault_mock).to receive(:save)
        end

        include_examples 'changing password'
        # Updating vault is tested by expectations in contextual_stubs
        include_examples 'deleting file'
      end
    end

    context 'when the vault item does not exist' do
      let(:contextual_stubs) {}
      let(:vault_item) {}

      it 'fails the chef run' do
        expect { subject }.to raise_error(ChefVault::Exceptions::ItemNotFound, /Vault item for admin password does not exist$/)
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

    let(:test_params) { { password_file_path: '/etc/splunk/password' } }
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
  end
end
