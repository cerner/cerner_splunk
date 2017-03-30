
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_roles' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['config']['roles'] = 'cerner_splunk/roles'
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

  let(:roles) do
    {
      'shcluster' => {
        'default' => {
          'app' => 'launcher',
          'tz' => 'America/Chicago',
          'showWhatsNew' => 0,
          'capabilities' => ['!schedule_rtsearch']
        }
      }
    }
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'apps').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'roles').and_return(roles)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the authorize.conf file with the appropriate access and capabilities' do
    expected_attributes = {
      config: {
        'default' => {
          'schedule_rtsearch' => 'disabled'
        }
      }
    }

    expect(subject).to configure_splunk('shcluster/apps/_shcluster/authorize.conf').with(expected_attributes)
    expect(subject.splunk_conf('shcluster/apps/_shcluster/authorize.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end

  it 'writes the user-prefs.conf file with the appropriate user preferences' do
    expected_attributes = {
      config: {
        'general_default' => {
          'default_namespace' => 'launcher',
          'tz' => 'America/Chicago',
          'showWhatsNew' => 0
        }
      }
    }

    expect(subject).to configure_splunk('shcluster/apps/_shcluster/user-prefs.conf').with(expected_attributes)
    expect(subject.splunk_conf('shcluster/apps/_shcluster/user-prefs.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
