
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_outputs' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.9') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.run_state.merge!('cerner_splunk' => { 'admin_password' => 'changeme' })
    end
    runner.converge('cerner_splunk::shc_deployer', described_recipe)
  end

  let(:cluster_config) do
    {
      'receivers' => ['33.33.33.11', '33.33.33.12'],
      'license_uri' => nil,
      'receiver_settings' => {
        'splunktcp' => {
          'port' => '9997'
        }
      },
      'indexes' => 'cerner_splunk/indexes',
      'apps' => 'cerner_splunk/apps',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'apps').and_return({})
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the outputs.conf file with the appropriate configs' do
    expected_attributes = {
      config: {
        'tcpout' => {
          'forwardedindex.0.whitelist' => '.*', 'forwardedindex.1.blacklist' => '_thefishbucket', 'forwardedindex.2.whitelist' => ''
        },
        'tcpout:cerner_splunk/cluster' => {
          'server' => '33.33.33.11:9997,33.33.33.12:9997'
        }
      }
    }

    expect(subject).to configure_splunk('shcluster/apps/_shcluster/outputs.conf').with(expected_attributes)
    expect(subject.splunk_conf('shcluster/apps/_shcluster/outputs.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
