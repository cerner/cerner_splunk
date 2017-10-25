# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::shc_deployer' do
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
      'apps' => 'cerner_splunk/apps',
      'shc_members' => [
        'https://33.33.33.15:8089',
        'https://33.33.33.17:8089'
      ]
    }
  end

  let(:apps) do
    {
      'deployer-apps' => {
        'test_app' => {
          'files' => {
            'app.conf' => {
              'ui' => {
                'is_visible' => '1',
                'label' => 'Test App'
              }
            }
          },
          'lookups' => {
            'index-owners.csv' => 'http://33.33.33.33:5000/lookups/index-owners.csv'
          }
        }
      }
    }
  end

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    stub_data_bag_item('cerner_splunk', 'apps').and_return(apps)
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

  it 'does not run apply-shcluster-bundle' do
    expect(subject).not_to run_execute('apply-shcluster-bundle')
  end

  it 'creates the _shcluster app and notifies the execute[apply-shcluster-bundle] resource to run' do
    expect(subject).to create_splunk_app('_shcluster')
    expect(subject.splunk_app('_shcluster')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end

  context 'when apps needs to be created on the deployer' do
    it 'installs the app with expected attributes and notifies the execute[apply-shcluster-bundle] resource to run' do
      expected_attributes = {
        lookups: {
          'index-owners.csv' => 'http://33.33.33.33:5000/lookups/index-owners.csv'
        },
        files: {
          'app.conf' => {
            'ui' => {
              'is_visible' => '1',
              'label' => 'Test App'
            }
          }
        }
      }
      expect(subject).to create_splunk_app('test_app').with(expected_attributes)
      expect(subject.splunk_app('test_app')).to notify('execute[apply-shcluster-bundle]').to(:run)
    end
  end

  context 'when apps need to be removed' do
    let(:apps) do
      {
        'deployer-apps' => {
          'test_app' => {
            'remove' => true
          }
        }
      }
    end

    it 'removes the app and notifies the execute[apply-shcluster-bundle] resource to run' do
      expect(subject).to remove_splunk_app('test_app')
      expect(subject.splunk_app('test_app')).to notify('execute[apply-shcluster-bundle]').to(:run)
    end
  end

  it 'includes cerner_splunk::_configure_shc_roles recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_shc_roles')
  end

  it 'includes cerner_splunk::_configure_shc_authentication recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_shc_authentication')
  end

  it 'includes cerner_splunk::_configure_shc_outputs recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_shc_outputs')
  end

  it 'includes cerner_splunk::_configure_shc_alerts recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_shc_alerts')
  end

  it 'includes cerner_splunk::_start recipe' do
    expect(subject).to include_recipe('cerner_splunk::_start')
  end
end
