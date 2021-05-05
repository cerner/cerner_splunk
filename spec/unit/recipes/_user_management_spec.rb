# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_user_management' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['user'] = 'splunk'
      node.override['splunk']['user_home'] = user_home
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:platform) { 'centos' }
  let(:platform_version) { '6.10' }
  let(:user_home) { nil }

  let(:windows) { nil }

  before do
    allow(Chef::Recipe).to receive(:platform_family?).with('windows').and_return(windows)
  end

  after do
    CernerSplunk.reset
  end

  context 'when platform is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }
    let(:windows) { true }

    it 'does nothing' do
      expect(subject).not_to create_user('splunk')
    end
  end

  context 'when platform is rhel' do
    let(:platform) { 'centos' }
    let(:platform_version) { '8' }

    context 'when the user_home is not set' do
      it 'ensures the splunk user exists' do
        expected_attrs = {
          manage_home: false
        }
        expect(subject).to create_user('splunk').with(expected_attrs)
      end

      it 'does not ensure the home directory exists' do
        expect(subject).not_to create_directory('/home/splunk')
      end
    end

    context 'when the user_home is set' do
      let(:user_home) { '/home/splunk' }
      it 'ensures the splunk user exists with the configured home directory' do
        expected_attrs = {
          manage_home: false,
          home: user_home
        }
        expect(subject).to create_user('splunk').with(expected_attrs)
      end

      it 'ensures the home directory exists' do
        expected_attrs = {
          user: 'splunk',
          group: 'splunk',
          mode: '0700'
        }
        expect(subject).to create_directory('/home/splunk').with(expected_attrs)
      end
    end
  end
end
