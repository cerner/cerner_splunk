# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_shc_authentication' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['config']['authentication'] = 'cerner_splunk/authentication'
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

  let(:auth) do
    {
      'shcluster' => {
        'LDAP_strategies' => {
          'bag' => 'ldap',
          'roleMap' => {
            'admin' => 'Super_Admin'
          }
        }
      }
    }
  end

  let(:ldap) do
    {
      'strategy_name' => 'ADDomain',
      'host' => 'ad.example.com',
      'SSLEnabled' => 1,
      'port' => 636,
      'bindDN' => 'bindacct@example.com',
      'userBaseDN' => ['OU=Users,DC=example,DC=com'],
      'userBaseFilter' => '(objectClass=user)',
      'userNameAttribute' => 'sAMAccountName',
      'realNameAttribute' => 'displayName',
      'groupBaseDN' => ['OU=Splunk Groups,DC=example,DC=com'],
      'groupBaseFilter' => '(objectClass=group)',
      'groupNameAttribute' => 'cn',
      'groupMemberAttribute' => 'member',
      'nestedGroups' => 1,
      'anonymous_referrals' => 0
    }
  end

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_data_bag_item('cerner_splunk', 'apps').and_return({})
    stub_data_bag_item('cerner_splunk', 'authentication').and_return(auth)
    stub_data_bag_item('cerner_splunk', 'ldap').and_return(ldap)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the authentication.conf file with the appropriate strategy and role Map' do
    expected_attributes = {
      stanzas: {
        'ADDomain' => {
          'host' => 'ad.example.com',
          'SSLEnabled' => 1,
          'port' => 636,
          'bindDN' => 'bindacct@example.com',
          'userBaseDN' => 'OU=Users,DC=example,DC=com',
          'userBaseFilter' => '(objectClass=user)',
          'userNameAttribute' => 'sAMAccountName',
          'realNameAttribute' => 'displayName',
          'groupBaseDN' => 'OU=Splunk Groups,DC=example,DC=com',
          'groupBaseFilter' => '(objectClass=group)',
          'groupNameAttribute' => 'cn',
          'groupMemberAttribute' => 'member',
          'nestedGroups' => 1,
          'anonymous_referrals' => 0
        },
        'authentication' => {
          'authType' => 'LDAP',
          'authSettings' => 'ADDomain'
        },
        'roleMap_ADDomain' => {
          'admin' => 'Super_Admin'
        }
      }
    }

    expect(subject).to create_splunk_template('shcluster/_shcluster/authentication.conf').with(expected_attributes)
    expect(subject.splunk_template('shcluster/_shcluster/authentication.conf')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end
end
