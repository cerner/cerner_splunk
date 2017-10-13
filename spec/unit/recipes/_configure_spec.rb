# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = clusters
      node.override['splunk']['node_type'] = node_type
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:node_type) { :server }

  let(:cluster_config) do
    {
      'receivers' => ['33.33.33.20'],
      'receiver_settings' => {
        'splunktcp' => {
          'port' => '9997'
        }
      },
      'indexes' => 'cerner_splunk/indexes'
    }
  end

  let(:clusters) { ['cerner_splunk/cluster'] }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  context 'when cluster databag is specified' do
    it 'includes cerner_splunk::_configure_server recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_server')
    end

    it 'includes cerner_splunk::_configure_roles recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_roles')
    end

    it 'includes cerner_splunk::_configure_authentication recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_authentication')
    end

    it 'includes cerner_splunk::_configure_inputs recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_inputs')
    end

    it 'includes cerner_splunk::_configure_outputs recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_outputs')
    end

    it 'includes cerner_splunk::_configure_alerts recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_alerts')
    end

    it 'includes cerner_splunk::_configure_apps recipe' do
      expect(subject).to include_recipe('cerner_splunk::_configure_apps')
    end
  end

  context 'when cluster is not specified' do
    let(:clusters) { [] }

    context 'when node is a forwarder' do
      let(:node_type) { :forwarder }

      it 'should raise a warning message' do
        expect(Chef::Log).to receive(:warn).with('No cluster data bag configured, ensure your outputs are configured elsewhere.')
        subject
      end
    end

    context 'when node is not a forwarder' do
      it 'should raise an exception' do
        expect { subject }.to raise_exception
      end
    end
  end
end
