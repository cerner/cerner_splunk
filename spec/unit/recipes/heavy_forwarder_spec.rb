# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::heavy_forwarder' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.run_state['cerner_splunk'] = {}
      node.run_state['cerner_splunk']['splunk_forwarder_migrate'] = splunk_installed
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
    allow(Dir).to receive(:exist?).with('/opt/splunkforwarder').and_return(splunk_installed)
  end

  after do
    CernerSplunk.reset
  end

  context 'when splunkforwarder is installed' do
    let(:splunk_installed) { true }

    it 'includes cerner_splunk::_migrate_forwarder recipe' do
      expect(subject).to include_recipe('cerner_splunk::_migrate_forwarder')
    end

    it 'runs initialize-splunk-backup-artifacts ruby block' do
      expect(subject).to run_ruby_block('initialize-splunk-backup-artifacts')
    end
  end

  context 'when splunkforwarder is not installed' do
    let(:splunk_installed) { false }

    it 'does not include cerner_splunk::_migrate_forwarder recipe' do
      expect(subject).not_to include_recipe('cerner_splunk::_migrate_forwarder')
    end

    it 'does not run initialize-splunk-backup-artifacts ruby block' do
      expect(subject).not_to run_ruby_block('initialize-splunk-backup-artifacts')
    end
  end

  it 'includes default cerner_splunk::_install recipe' do
    expect(subject).to include_recipe('cerner_splunk::_install')
  end

  it 'includes default cerner_splunk::_start recipe' do
    expect(subject).to include_recipe('cerner_splunk::_start')
  end
end
