
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::shc_captain' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '7.2') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end
    runner.converge(described_recipe)
  end

  let(:cluster_config) do
    {
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

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  context 'when the search heads are not specified for sh clustering in the cluster databag' do
    let(:cluster_config) do
      {
        'sh_cluster' => []
      }
    end

    it 'raises an error' do
      message = 'Search Heads are not configured for sh clustering in the cluster databag'
      expect { subject }.to raise_error(RuntimeError, message)
    end
  end

  it 'includes cerner_splunk::_install_server recipe' do
    expect(subject).to include_recipe('cerner_splunk::_install_server')
  end

  it 'does not include cerner_splunk::_configure_ui recipe' do
    expect(subject).not_to include_recipe('cerner_splunk::_configure_ui')
  end

  it 'includes cerner_splunk::_start recipe' do
    expect(subject).to include_recipe('cerner_splunk::_start')
  end

  it 'assigns the captain' do
    expect(subject).to initialize_sh_cluster('Captain assignment')
  end
end
