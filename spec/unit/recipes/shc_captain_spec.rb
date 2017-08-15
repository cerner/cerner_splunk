
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::shc_captain' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.9') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['config']['password_secrets'] = { 'shc_captain': 'cerner_splunk/shc_passwords' }
      node.run_state.merge!('cerner_splunk' => { 'admin_password' => 'changeme' })
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
        'https://33.33.33.15:8089',
        'https://33.33.33.16:8089'
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

  it { is_expected.to include_recipe('cerner_splunk::_install_server') }
  it { is_expected.to include_recipe('cerner_splunk::_start') }
  it { is_expected.to initialize_cerner_splunk_sh_cluster('Captain assignment') }

  context 'when the search heads are not specified for sh clustering in the cluster databag' do
    let(:cluster_config) { { 'sh_cluster' => [] } }

    it 'raises an error' do
      message = 'Search Heads are not configured for sh clustering in the cluster databag'
      expect { subject }.to raise_error(RuntimeError, message)
    end
  end
end
