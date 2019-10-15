# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk_sh_cluster:add' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.10', step_into: ['cerner_splunk_sh_cluster']) do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['cmd'] = '/opt/splunk/bin/splunk'
      node.override['splunk']['package']['base_name'] = 'base_name'
      node.override['splunk']['package']['download_group'] = 'download_group'
    end
    runner.converge('cerner_splunk::_install', 'cerner_splunk::shc_search_head')
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
      'indexes' => 'cerner_splunk/indexes',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).with('cerner_splunk', 'cluster').and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_command('/opt/splunk/bin/splunk list shcluster-members -auth admin:changeme | grep 10.0.0.2').and_return(existing_member)
  end

  after do
    CernerSplunk.reset
  end

  context 'when a new member needs to be added to the cluster and is not an existing member of the cluster' do
    let(:existing_member) { false }

    it 'adds the SH to the SHC' do
      expect(subject).to run_execute('add search head')
    end
  end

  context 'when a new member needs to be added to the cluster and is an existing member of the cluster' do
    let(:existing_member) { true }

    it 'does not add the SH to the SHC' do
      expect(subject).not_to run_execute('add search head')
    end
  end
end

describe 'cerner_splunk_sh_cluster:remove' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.10', step_into: ['cerner_splunk_sh_cluster']) do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['cmd'] = '/opt/splunk/bin/splunk'
      node.override['splunk']['package']['base_name'] = 'base_name'
      node.override['splunk']['package']['download_group'] = 'download_group'
    end
    runner.converge('cerner_splunk::_install', 'cerner_splunk::shc_remove_search_head')
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
      'indexes' => 'cerner_splunk/indexes',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  let(:existing_member) { nil }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).with('cerner_splunk', 'cluster').and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_command('/opt/splunk/bin/splunk list shcluster-members -auth admin:changeme | grep 10.0.0.2').and_return(existing_member)
  end

  after do
    CernerSplunk.reset
  end

  context 'when a member needs to be removed from the cluster and is an existing member of the cluster' do
    let(:existing_member) { true }

    it 'removes the SH from the SHC' do
      expect(subject).to run_execute('remove search head')
    end
  end

  context 'when a member needs to be removed from the cluster and is not an existing member of the cluster' do
    let(:existing_member) { false }

    it 'does not remove the SH from the SHC' do
      expect(subject).not_to run_execute('remove search head')
    end
  end
end

describe 'cerner_splunk_sh_cluster:initialize' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.10', step_into: ['cerner_splunk_sh_cluster']) do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['cmd'] = '/opt/splunk/bin/splunk'
      node.override['splunk']['package']['base_name'] = 'base_name'
      node.override['splunk']['package']['download_group'] = 'download_group'
    end
    runner.converge('cerner_splunk::_install', 'cerner_splunk::shc_captain')
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
      'indexes' => 'cerner_splunk/indexes',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  let(:captain_exist) { nil }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).with('cerner_splunk', 'cluster').and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_command('/opt/splunk/bin/splunk list shcluster-members -auth admin:changeme | grep is_captain:1').and_return(captain_exist)
  end

  after do
    CernerSplunk.reset
  end

  context 'when the captain needs to be assigned and a captain does not exist in the cluster' do
    let(:captain_exist) { false }
    it 'assigns the SH to be the captain' do
      expect(subject).to run_execute('Captain assignment')
    end
  end

  context 'when the captain needs to be assigned and a captain already exist in the cluster' do
    let(:captain_exist) { true }
    it 'does not assign the SH to be the captain' do
      expect(subject).not_to run_execute('Captain assignment')
    end
  end
end
