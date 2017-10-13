# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_secret' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['node_type'] = node_type
      node.override['splunk']['home'] = '/opt/splunk'
      node.override['splunk']['config']['secrets'] = node_config_secrets
    end
    runner.converge(described_recipe)
  end

  let(:platform) { 'centos' }
  let(:platform_version) { '6.6' }
  let(:node_type) { :server }

  context 'when the secret is configured for the current node' do
    let(:node_config_secrets) do
      {
        'server' => 'cerner_splunk/secrets:splunk.secret'
      }
    end
    let(:secret_data_bag) do
      {
        'splunk.secret' => configured_secret
      }
    end
    let(:configured_secret) { 'ThisIsMySplunkSecret' }

    before do
      allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:vault)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'secrets').and_return(secret_data_bag)
    end

    it 'validates the secret file and writes the template' do
      expect(subject).to run_ruby_block('Check splunk.secret file')
      expect(subject).to create_file('splunk.secret').with(content: "#{configured_secret}\n")
    end

    context 'and the platform is windows' do
      let(:platform) { 'windows' }
      let(:platform_version) { '2012R2' }

      it 'does nothing' do
        expect(subject).not_to create_file('splunk.secret')
      end
    end

    context 'and the configured value does not indicate a valid data bag item' do
      let(:node_config_secrets) do
        {
          'server' => 'asfasdf'
        }
      end

      it 'raises an error' do
        message = 'Configured splunk secret must resolve to a String'
        expect { subject }.to raise_error(RuntimeError, message)
      end
    end

    context 'and the configured data bag item key is not a string' do
      let(:secret_data_bag) do
        {
          'splunk.secret' => { this: 'is', not_a: 'string' }
        }
      end

      it 'raises an error' do
        message = 'Configured splunk secret must resolve to a String'
        expect { subject }.to raise_error(RuntimeError, message)
      end
    end
  end

  context 'when the secret is configured for a different node' do
    let(:node_config_secrets) do
      {
        'forwarder' => 'cerner_splunk/secrets:splunk.secret'
      }
    end

    it 'does nothing' do
      expect(subject).not_to create_file('splunk.secret')
    end
  end

  context 'when the secret is not configured' do
    let(:node_config_secrets) { nil }

    it 'does nothing' do
      expect(subject).not_to create_file('splunk.secret')
    end
  end
end
