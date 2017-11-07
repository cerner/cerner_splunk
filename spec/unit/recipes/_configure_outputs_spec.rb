# coding: UTF-8

require_relative '../spec_helper'

shared_examples 'when receivers or port is not configured' do
  it 'logs a warning' do
    message = 'Receiver settings missing or incomplete in configured cluster data bag: cerner_splunk/cluster'
    expect(Chef::Log).to receive(:warn).with(message)
    subject
  end
end

shared_examples 'when indexer discovery is set to true and master_uri is empty or not configured' do
  it 'fails with an error' do
    message = 'master_uri is missing in the cluster databag: cerner_splunk/indexer_discovery_configs'
    expect { subject }.to raise_error(RuntimeError, message)
  end
end

describe 'cerner_splunk::_configure_outputs' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster', 'cerner_splunk/indexer_discovery_configs']
      node.override['splunk']['node_type'] = node_type
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:receiver_list) { ['33.33.33.11', '33.33.33.12'] }
  let(:receivers) { { 'receivers' => receiver_list } }
  let(:port) { '9997' }

  let(:cluster_config) do
    {
      'license_uri' => nil,
      'tcpout_settings' => {
        'autoLBFrequency' => 30
      },
      'receiver_settings' => {
        'splunktcp' => {
          'port' => port
        }
      }
    }.merge(receivers)
  end

  let(:outputs_config_values) { {} }
  let(:outputs_configs) { {} }

  let(:indexer_discovery_settings) do
    {
      'pass4SymmKey' => 'fake_password'
    }.merge(outputs_configs)
  end

  let(:indexer_discovery_config) do
    {
      'master_uri' => master_uri,
      'indexer_discovery' => true,
      'indexer_discovery_settings' => indexer_discovery_settings,
      'tcpout_settings' => {
        'useACK' => true,
        'autoLBFrequency' => 30
      }
    }
  end

  let(:master_uri) { 'https://cluster-master:8089' }
  let(:node_type) { :forwarder }

  before do
    allow(CernerSplunk::ConfTemplate).to receive(:compose).and_return('fake_password')
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexer_discovery_configs').and_return(indexer_discovery_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  context 'when the node is forwarder' do
    it 'writes the outputs.conf file with the appropriate configs for all the cluster databags' do
      expected_attributes = {
        stanzas: {
          'tcpout' => {
            'forwardedindex.0.whitelist' => '.*', 'forwardedindex.1.blacklist' => '_thefishbucket', 'forwardedindex.2.whitelist' => ''
          },
          'tcpout:cerner_splunk/cluster' => {
            'server' => '33.33.33.11:9997,33.33.33.12:9997',
            'autoLBFrequency' => 30
          },
          'tcpout:cerner_splunk/indexer_discovery_configs' => {
            'useACK' => true,
            'autoLBFrequency' => 30,
            'indexerDiscovery' => 'cerner_splunk/indexer_discovery_configs'
          },
          'indexer_discovery:cerner_splunk/indexer_discovery_configs' => {
            'master_uri' => 'https://cluster-master:8089',
            'pass4SymmKey' => 'fake_password'
          }
        }
      }
      expect(subject).to create_splunk_template('system/outputs.conf').with(expected_attributes)
      expect(subject.splunk_template('system/outputs.conf')).to notify('file[splunk-marker]').to(:touch)
    end
  end

  context 'when the node is a search_head' do
    let(:node_type) { :search_head }

    context 'when receivers are configured' do
      it 'writes the outputs.conf file with the appropriate configs only from my cluster' do
        expected_attributes = {
          stanzas: {
            'tcpout' => {
              'forwardedindex.0.whitelist' => '.*', 'forwardedindex.1.blacklist' => '_thefishbucket', 'forwardedindex.2.whitelist' => ''
            },
            'tcpout:cerner_splunk/cluster' => {
              'server' => '33.33.33.11:9997,33.33.33.12:9997',
              'autoLBFrequency' => 30
            }
          }
        }
        expect(subject).to create_splunk_template('system/outputs.conf').with(expected_attributes)
        expect(subject.splunk_template('system/outputs.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end

    context 'when receivers is an empty array' do
      let(:receiver_list) { [] }

      include_examples 'when receivers or port is not configured'
    end

    context 'when receivers is not configured' do
      let(:receivers) { {} }

      include_examples 'when receivers or port is not configured'
    end

    context 'when port is not configured' do
      let(:port) {}

      include_examples 'when receivers or port is not configured'
    end
  end

  context 'when indexer_discovery is set to true and master_uri is not configured' do
    context 'when master_uri is not set' do
      let(:indexer_discovery_config) { { 'indexer_discovery' => true } }

      include_examples 'when indexer discovery is set to true and master_uri is empty or not configured'
    end

    context 'when master_uri is empty' do
      let(:master_uri) { '' }

      include_examples 'when indexer discovery is set to true and master_uri is empty or not configured'
    end
  end

  context 'when indexer_discovery is set to true' do
    context 'when attributes are configured in outputs_config hash' do
      let(:outputs_config_values) { { 'send_timeout' => 30, 'rcv_timeout' => 30 } }
      let(:outputs_configs) { { 'outputs_configs' => outputs_config_values } }
      expected_attributes = {
        stanzas: {
          'tcpout' => {
            'forwardedindex.0.whitelist' => '.*', 'forwardedindex.1.blacklist' => '_thefishbucket', 'forwardedindex.2.whitelist' => ''
          },
          'tcpout:cerner_splunk/cluster' => {
            'server' => '33.33.33.11:9997,33.33.33.12:9997',
            'autoLBFrequency' => 30
          },
          'tcpout:cerner_splunk/indexer_discovery_configs' => {
            'autoLBFrequency' => 30,
            'useACK' => true,
            'indexerDiscovery' => 'cerner_splunk/indexer_discovery_configs'
          },
          'indexer_discovery:cerner_splunk/indexer_discovery_configs' => {
            'master_uri' => 'https://cluster-master:8089',
            'pass4SymmKey' => 'fake_password',
            'send_timeout' => 30,
            'rcv_timeout' => 30
          }
        }
      }
      it 'writes the attributes to the indexer_discovery stanza' do
        expect(subject).to create_splunk_template('system/outputs.conf').with(expected_attributes)
        expect(subject.splunk_template('system/outputs.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end

    context 'when receivers are configured' do
      let(:indexer_discovery_config) { { 'indexer_discovery' => true, 'receivers' => ['33.33.33.11', '33.33.33.12'], 'master_uri' => master_uri } }

      it 'logs a warning message' do
        message = "Configured ['receivers'] in cluster cerner_splunk/indexer_discovery_configs will be ignored since ['indexer_discovery'] is set to true."
        expect(Chef::Log).to receive(:warn).with(message)
        subject
      end
    end
  end
end
