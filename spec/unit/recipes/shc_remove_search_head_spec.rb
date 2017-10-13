# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::shc_remove_search_head' do
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
      'indexes' => 'cerner_splunk/indexes',
      'shc_members' => [
        'https://33.33.33.16:8089',
        'https://33.33.33.17:8089'
      ],
      'deployer_uri' => 'https://33.33.33.28:8089',
      'replication_ports' => {
        '8080' => {}
      }
    }
  end

  let(:bootstrap_shc_member) { false }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  it 'includes cerner_splunk::shc_search_head recipe' do
    expect(subject).to include_recipe('cerner_splunk::shc_search_head')
  end

  it 'removes the search head from the cluster' do
    expect(subject).to remove_sh_member('remove SH from SHC')
  end

  it 'runs the ruby block splunk-stop' do
    expect(subject).to run_ruby_block('splunk-stop')
  end
end
