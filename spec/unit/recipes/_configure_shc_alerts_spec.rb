# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_alerts' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['config']['alerts'] = 'cerner_splunk/alerts'
    end
    runner.converge('cerner_splunk::shc_deployer', described_recipe)
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
      'apps' => 'cerner_splunk/apps',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  let(:alerts) do
    {
      'shcluster' => {
        'bag' => ':base',
        'email' => {
          'reportServerEnabled' => false
        }
      },
      'base' => {
        'email' => {
          'mailserver' => 'smtprr.example.com',
          'from' => 'splunk@example.com',
          'reportServerEnabled' => true
        }
      }
    }
  end

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_data_bag_item('cerner_splunk', 'apps').and_return({})
    stub_data_bag_item('cerner_splunk', 'alerts').and_return(alerts)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the alert_actions.conf file with the appropriate alert configs' do
    expected_attributes = {
      stanzas: {
        'email' => {
          'mailserver' => 'smtprr.example.com',
          'from' => 'splunk@example.com',
          'reportServerEnabled' => false
        }
      }
    }

    expect(subject).to create_splunk_template('shcluster/_shcluster/alert_actions.conf').with(expected_attributes)
    expect(subject.splunk_template('shcluster/_shcluster/alert_actions.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
