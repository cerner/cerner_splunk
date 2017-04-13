
# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../../libraries/app_helpers'

describe 'cerner_splunk::shc_deployer' do
  subject do
    ChefSpec::SoloRunner.new(platform: 'redhat', version: '7.2') do |node|
      chef_run_stubs
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end.converge(described_recipe)
  end

  let(:app_config) {}
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

  let(:expected_cluster_app_config) do
    {
      lookups: {},
      files: {
        'app.conf' => {
          'ui' => {
            'is_visible' => '0',
            'label' => 'Deployer Configs App'
          }
        },
        'ui-prefs.conf' => {
          'default' => {
            'dispatch.earliest_time' => '@d',
            'dispatch.latest_time' => 'now',
            'display.prefs.enableMetaData' => 0,
            'display.prefs.showDataSummary' => 0
          }
        }
      }
    }
  end

  let(:chef_run_stubs) do
    shared_stubs
    action_stubs
  end

  let(:shared_stubs) do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'apps').and_return(app_config)
  end

  let(:action_stubs) do
    expect(CernerSplunk::AppHelpers).to receive(:proc_conf).with(expected_cluster_app_config[:files])
    expect(CernerSplunk::AppHelpers).to receive(:proc_files).with(expected_cluster_app_config)
  end

  after do
    CernerSplunk.reset
  end

  it { is_expected.to include_recipe('cerner_splunk::_install_server') }
  it { is_expected.not_to run_execute('apply-shcluster-bundle') }
  it { is_expected.to install_splunk_app_custom('_shcluster') }

  it 'should notify the execute[apply-shcluster-bundle] resource to run' do
    expect(subject.splunk_app_custom('_shcluster')).to notify('execute[apply-shcluster-bundle]').to(:run)
  end

  context 'when installing cluster apps' do
    let(:app_config) do
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
    let(:expected_attributes) do
      {
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
    end

    let(:action_stubs) do
      expect(CernerSplunk::AppHelpers).to receive(:proc_conf).with(expected_cluster_app_config[:files])
      expect(CernerSplunk::AppHelpers).to receive(:proc_files).with(expected_cluster_app_config)
      expect(CernerSplunk::AppHelpers).to receive(:proc_conf).with(expected_attributes[:files])
      expect(CernerSplunk::AppHelpers).to receive(:proc_files).with(expected_attributes)
    end

    it { is_expected.to install_splunk_app_custom('test_app') }

    it 'should notify the execute[apply-shcluster-bundle] resource to run' do
      expect(subject.splunk_app_custom('test_app')).to notify('execute[apply-shcluster-bundle]').to(:run)
    end
  end

  context 'when uninstalling cluster apps' do
    let(:app_config) do
      {
        'deployer-apps' => {
          'test_app' => {
            'remove' => true
          }
        }
      }
    end

    it { is_expected.to uninstall_splunk_app_custom('test_app') }

    it 'should notify the execute[apply-shcluster-bundle] resource to run' do
      expect(subject.splunk_app_custom('test_app')).to notify('execute[apply-shcluster-bundle]').to(:run)
    end
  end

  it { is_expected.to include_recipe('cerner_splunk::_configure_shc_roles') }
  it { is_expected.to include_recipe('cerner_splunk::_configure_shc_authentication') }
  it { is_expected.to include_recipe('cerner_splunk::_configure_shc_outputs') }
  it { is_expected.to include_recipe('cerner_splunk::_configure_shc_alerts') }
  it { is_expected.to include_recipe('cerner_splunk::_start') }

  context 'when the search heads are not specified for sh clustering in the cluster databag' do
    let(:action_stubs) {}
    let(:cluster_config) do
      {
        'sh_cluster' => []
      }
    end

    it 'should raise an error' do
      message = 'Search Heads are not configured for sh clustering in the cluster databag'
      expect { subject }.to raise_error(message)
    end
  end
end
