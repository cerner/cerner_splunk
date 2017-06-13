
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::shc_remove_search_head' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['config']['password_secrets'] = { 'shc_search_head': 'cerner_splunk/shc_passwords' }
      node.override['splunk']['bootstrap_shc_member'] = bootstrap_shc_member
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
        'https://33.33.33.16:8089',
        'https://33.33.33.17:8089'
      ],
      'deployer_uri' => 'https://33.33.33.28:8089',
      'replication_ports' => {
        '8080' => {}
      }
    }
  end

  let(:bootstrap_shc_member) { true }

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  it { is_expected.to include_recipe('cerner_splunk::shc_search_head') }

  it { is_expected.not_to add_sh_member('add SH to SHC') }
  it { is_expected.to remove_sh_member('remove SH from SHC') }

  it 'notifies the splunk service to stop' do
    expect(subject.cerner_splunk_sh_cluster('remove SH from SHC')).to notify('splunk_service[splunk]').to(:stop).immediately
  end
end
