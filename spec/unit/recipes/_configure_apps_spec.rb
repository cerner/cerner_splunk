
# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../../libraries/app_helpers'

describe 'cerner_splunk::_configure_apps' do
  let(:chef_run_stubs) {}

  subject do
    ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.9') do |node|
      chef_run_stubs
      node.normal['splunk']['package']['type'] = 'splunk'
      node.normal['splunk']['apps'] = app_config
    end.converge('cerner_splunk_test::init_splunk_service', described_recipe)
  end

  let(:app_config) do
    {
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
  end

  context 'when installing an app' do
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

    let(:chef_run_stubs) do
      expect(CernerSplunk::AppHelpers).to receive(:proc_files).with(expected_attributes)
      expect(CernerSplunk::AppHelpers).to receive(:proc_conf).with(expected_attributes[:files])
    end

    it { is_expected.to install_splunk_app_custom('test_app') }
    it 'should notify the splunk service to restart' do
      expect(subject.splunk_app_custom('test_app')).to notify('splunk_service[splunk]').to(:desired_restart).immediately
    end
  end

  context 'when uninstalling the app' do
    let(:app_config) do
      {
        'test_app' => {
          'remove' => true
        }
      }
    end

    it { is_expected.to uninstall_splunk_app_custom('test_app') }
    it 'should notify the splunk service to restart' do
      expect(subject.splunk_app_custom('test_app')).to notify('splunk_service[splunk]').to(:desired_restart).immediately
    end
  end
end
