# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_server' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = clusters
      node.override['splunk']['config']['host'] = node_type.to_s
      node.override['splunk']['node_type'] = node_type
      node.override['splunk']['forwarder_site'] = 'site1'
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:master_uri) { 'https://cluster-master:8089' }
  let(:replication_port) { {} }
  let(:receiver_settings) { { 'splunktcp' => { 'port' => '9997' } }.merge(replication_port) }
  let(:expected_site) { {} }
  let(:multisite) { {}.merge(site) }
  let(:clusters) { ['cerner_splunk/multisite_cluster', 'cerner_splunk/standalone', 'cerner_splunk/singlesite_cluster'] }

  let(:standalone_configs) do
    {
      'license_uri' => nil,
      'receivers' => ['33.33.33.12']
    }.merge(receiver_settings)
  end

  let(:singlesite_cluster_configs) do
    {
      'license_uri' => nil,
      'master_uri' => master_uri,
      'deployer_uri' => 'https://shc-deployer-uri:8089',
      'settings' => {
        'replication_factor' => 2,
        'search_factor' => 2,
        '_cerner_splunk_indexer_count' => 3
      },
      'receivers' => [
        '33.33.33.12',
        '33.33.33.13',
        '33.33.33.14'
      ]
    }.merge(receiver_settings)
  end

  let(:multisite_cluster_configs) do
    {
      'license_uri' => nil,
      'master_uri' => master_uri,
      'deployer_uri' => 'https://shc-deployer-uri:8089',
      'indexer_discovery' => true,
      'site' => 'site1',
      'multisite' => 'cerner_splunk/multisite_bag',
      'receivers' => [
        '33.33.33.12',
        '33.33.33.13',
        '33.33.33.14'
      ]
    }.merge(receiver_settings)
  end

  let(:multisite_bag_configs) do
    {
      'sites' => ['cerner_splunk/multisite_cluster'],
      'multisite_settings' =>   {
        'forwarder_site_failover' => 'site1:site2',
        'site_replication_factor' => 'origin:2,total:3',
        'site_search_factor' => 'origin:1,total:2'
      }
    }
  end

  let(:expected_license_attributes) do
    {
      'lmpool:auto_generated_pool_download-trial' => {
        'description' => 'auto_generated_pool_download-trial',
        'quota' => 'MAX',
        'slaves' => '*',
        'stack_id' => 'download-trial'
      },
      'lmpool:auto_generated_pool_enterprise' => {
        'description' => 'auto_generated_pool_enterprise',
        'quota' => 'MAX',
        'slaves' => '*',
        'stack_id' => 'enterprise'
      },
      'lmpool:auto_generated_pool_forwarder' => {
        'description' => 'auto_generated_pool_forwarder',
        'quota' => 'MAX',
        'slaves' => '*',
        'stack_id' => 'forwarder'
      },
      'lmpool:auto_generated_pool_free' => {
        'description' => 'auto_generated_pool_free',
        'quota' => 'MAX',
        'slaves' => '*',
        'stack_id' => 'free'
      }
    }
  end
  let(:expected_active_group) { 'Forwarder' }
  let(:expected_clustering) { {} }
  let(:expected_replication_configs) { { 'replication_port://8080' => {} } }

  let(:expected_general_stanza) { { 'serverName' => node_type.to_s, 'pass4SymmKey' => 'fake_password' }.merge(expected_site) }
  let(:expected_attributes) do
    {
      'general' => expected_general_stanza,
      'sslConfig' => {
        'sslPassword' => 'fake_password'
      },
      'license' => {
        'master_uri' => 'self',
        'active_group' => expected_active_group
      }
    }.merge(expected_license_attributes).merge(expected_clustering)
  end

  before do
    allow(CernerSplunk::ConfTemplate).to receive(:compose).and_return('fake_password')
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'standalone').and_return(standalone_configs)
    stub_data_bag_item('cerner_splunk', 'singlesite_cluster').and_return(singlesite_cluster_configs)
    stub_data_bag_item('cerner_splunk', 'multisite_cluster').and_return(multisite_cluster_configs)
    stub_data_bag_item('cerner_splunk', 'multisite_bag').and_return(multisite_bag_configs)
  end

  after do
    CernerSplunk.reset
  end

  context 'when multisite cluster' do
    context 'when the node is a forwarder' do
      context 'when a site is specified' do
        let(:node_type) { :forwarder }
        let(:expected_site) { { 'site' => 'site1' } }

        it 'writes the server.conf file with the appropriate configs' do
          expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
          expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
        end
      end
    end

    context 'when the node is a cluster master' do
      let(:node_type) { :cluster_master }
      let(:expected_active_group) { 'Trial' }
      let(:expected_clustering) { { 'indexer_discovery' => {}, 'clustering' => { 'site_replication_factor' => 'origin:2,total:3', 'site_search_factor' => 'origin:1,total:2', 'multisite' => true, 'available_sites' => 'site1', 'forwarder_site_failover' => 'site1:site2', 'mode' => 'master' } } }
      let(:expected_site) { { 'site' => 'site1' } }

      it 'writes the server.conf file with the appropriate configs' do
        expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
        expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end

    context 'when the node is a cluster slave' do
      let(:node_type) { :cluster_slave }
      let(:expected_active_group) { 'Trial' }
      let(:expected_site) { { 'site' => 'site1' } }
      let(:replication_port) { { 'replication_ports' => { '8080' => {} } } }
      let(:expected_clustering) { { 'clustering' => { 'master_uri' => 'https://cluster-master:8089', 'mode' => 'slave' } } }

      it 'writes the server.conf file with the appropriate configs' do
        expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes.merge(expected_replication_configs))
        expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end
  end

  context 'when singlesite cluster' do
    let(:clusters) { ['cerner_splunk/singlesite_cluster'] }

    context 'when the node is a cluster master' do
      let(:node_type) { :cluster_master }
      let(:expected_active_group) { 'Trial' }
      let(:expected_clustering) { { 'clustering' => { 'replication_factor' => 2, 'search_factor' => 2, 'mode' => 'master' } } }

      it 'writes the server.conf file with the appropriate configs' do
        expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
        expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end

    context 'when the node is a cluster slave' do
      let(:node_type) { :cluster_slave }
      let(:expected_active_group) { 'Trial' }
      let(:replication_port) { { 'replication_ports' => { '8080' => {} } } }
      let(:expected_clustering) { { 'clustering' => { 'master_uri' => 'https://cluster-master:8089', 'mode' => 'slave' } } }

      it 'writes the server.conf file with the appropriate configs' do
        expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes.merge(expected_replication_configs))
        expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end

    context 'when the node is a forwarder' do
      let(:node_type) { :forwarder }
      let(:expected_site) { { 'site' => 'site1' } }

      it 'writes the server.conf file with the appropriate configs' do
        expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
        expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
      end
    end
  end

  context 'when the node is a search head and should search a multisite and singlesite cluster' do
    let(:clusters) { ['cerner_splunk/singlesite_cluster', 'cerner_splunk/multisite_cluster', 'cerner_splunk/standalone'] }
    let(:node_type) { :search_head }
    let(:expected_active_group) { 'Trial' }
    let(:expected_clustering) do
      {
        'clustering' => {
          'mode' => 'searchhead',
          'master_uri' => 'clustermaster:cerner_splunk/singlesite_cluster,clustermaster:cerner_splunk/multisite_cluster'
        },
        'clustermaster:cerner_splunk/multisite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => true,
          'site' => 'site1'
        },
        'clustermaster:cerner_splunk/singlesite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => false
        }
      }
    end

    it 'writes the server.conf file with the appropriate configs' do
      expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
      expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
    end
  end

  context 'when node is a search head and should search only a singlesite cluster' do
    let(:clusters) { ['cerner_splunk/singlesite_cluster'] }
    let(:node_type) { :search_head }
    let(:expected_active_group) { 'Trial' }
    let(:expected_clustering) do
      {
        'clustering' => {
          'master_uri' => 'clustermaster:cerner_splunk/singlesite_cluster',
          'mode' => 'searchhead'
        },
        'clustermaster:cerner_splunk/singlesite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => false
        }
      }
    end

    it 'writes the server.conf file with the appropriate configs' do
      expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
      expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
    end
  end

  context 'when node is a server' do
    let(:node_type) { :server }
    let(:expected_active_group) { 'Trial' }
    let(:expected_clustering) do
      {
        'clustering' => {
          'master_uri' => 'clustermaster:cerner_splunk/multisite_cluster,clustermaster:cerner_splunk/singlesite_cluster',
          'mode' => 'searchhead'
        },
        'clustermaster:cerner_splunk/multisite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => true,
          'site' => 'site1'
        },
        'clustermaster:cerner_splunk/singlesite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => false
        }
      }
    end

    it 'writes the server.conf file with the appropriate configs' do
      expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
      expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
    end
  end

  context 'when node is a shc_captain' do
    let(:node_type) { :shc_captain }
    let(:expected_active_group) { 'Trial' }
    let(:replication_port) { { 'replication_ports' => { '8080' => {} } } }
    let(:expected_clustering) do
      {
        'clustering' => {
          'master_uri' => 'clustermaster:cerner_splunk/multisite_cluster,clustermaster:cerner_splunk/singlesite_cluster',
          'mode' => 'searchhead'
        },
        'clustermaster:cerner_splunk/multisite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => true,
          'site' => 'site1'
        },
        'clustermaster:cerner_splunk/singlesite_cluster' => {
          'master_uri' => 'https://cluster-master:8089',
          'multisite' => false
        },
        'replication_port://8080' => {},
        'shclustering' => {
          'conf_deploy_fetch_url' => 'https://shc-deployer-uri:8089',
          'disabled' => 0,
          'mgmt_uri' => 'https://10.0.0.2:8089'
        }
      }
    end

    it 'writes the server.conf file with the appropriate configs' do
      expect(subject).to create_splunk_template('system/server.conf').with(stanzas: expected_attributes)
      expect(subject.splunk_template('system/server.conf')).to notify('file[splunk-marker]').to(:touch)
    end
  end
end
