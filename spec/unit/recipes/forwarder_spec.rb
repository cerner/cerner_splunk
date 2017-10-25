# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::forwarder' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end
    runner.converge(described_recipe)
  end

  let(:cluster_config) do
    {
      'receivers' => ['33.33.33.20'],
      'license_uri' => nil,
      'receiver_settings' => {
        'splunktcp' => {
          'port' => '9997'
        }
      },
      'indexes' => 'cerner_splunk/indexes'
    }
  end

  let(:splunk_installed) { nil }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})

    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with('/opt/splunk').and_return(splunk_installed)
  end

  after do
    CernerSplunk.reset
  end

  context 'when splunk is installed' do
    let(:splunk_installed) { true }

    it 'raises error' do
      message = 'Different Splunk artifact already installed on node. Failing as an unsupported install'
      expect { subject }.to raise_error(RuntimeError, message)
    end
  end

  context 'when splunk is not installed' do
    let(:splunk_installed) { false }

    it 'includes default cerner_splunk::_install recipe' do
      expect(subject).to include_recipe('cerner_splunk::_install')
    end

    it 'includes default cerner_splunk::_start recipe' do
      expect(subject).to include_recipe('cerner_splunk::_start')
    end
  end
end
