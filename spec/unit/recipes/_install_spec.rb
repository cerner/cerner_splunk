# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_install' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.normal['splunk']['cmd'] = 'splunk'
      # node.normal['splunk']['user'] = 'splunk
      node.normal['splunk']['package']['type'] = 'universal_forwarder'
      node.normal['splunk']['package']['base_name'] = 'splunkforwarder'
      node.normal['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
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
      'indexes' => 'cerner_splunk/indexes'
    }
  end

  let(:platform) { 'redhat' }
  let(:platform_version) { '6.8' }

  let(:initd_exists) { nil }
  let(:ui_login_exists) { nil }
  let(:ftr_exists) { nil }
  let(:glob) { [] }

  let(:windows) { nil }

  let(:splunk_file) { 'splunkforwarder-6.6.2-4b804538c686' }
  let(:splunk_filepath) { "/var/chef/cache/#{splunk_file}.txt" }

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
    allow(Chef::Recipe).to receive(:platform_family?).with('windows').and_return(windows)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/etc/init.d/splunk').and_return(initd_exists)
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/etc/.ui_login').and_return(ui_login_exists)
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/ftr').and_return(ftr_exists)

    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/opt/splunkforwarder/splunkforwarder-6.6.2-4b804538c686-*').and_return(glob)

    # Stub alt separator for windows in Ruby 1.9.3
    stub_const('::File::ALT_SEPARATOR', '/')
  end

  after do
    CernerSplunk.reset
  end

  it { is_expected.to include_recipe('chef-vault::default') }

  let(:expected_properties) do
    {
      package: :universal_forwarder,
      version: '6.5.3',
      build: '36937ad027d4',
      user: 'splunk',
      base_url: 'https://download.splunk.com/products'
    }
  end

  it { is_expected.to install_splunk('splunk').with(expected_properties) }
  it { is_expected.to init_splunk_service('universal_forwarder').with(package: expected_properties[:package], ulimit: 8192) }
  it { is_expected.to run_ruby_block('read splunk.secret') }

  # TODO: We test for windows but cerner_splunk does not, what happened?

  context 'when platform is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }
    let(:windows) { true }
    let(:expected_properties) do
      {
        package: :universal_forwarder,
        version: '6.5.3',
        build: '36937ad027d4',
        user: 'fauxhai',
        base_url: 'https://download.splunk.com/products'
      }
    end

    before do
      ENV['PROGRAMW6432'] = 'test'
    end

    it { is_expected.to install_splunk('splunk').with(expected_properties) }
    it { is_expected.to init_splunk_service('universal_forwarder').with(package: expected_properties[:package]) }
  end

  it { is_expected.to include_recipe('cerner_splunk::_configure_secret') }
  it { is_expected.to create_directory('/etc/splunk').with(owner: 'splunk', group: 'splunk', mode: '0700') }
  it { is_expected.to create_directory('/opt/splunkforwarder/var/log/introspection').with(owner: 'splunk', group: 'splunk', mode: '0700') }

  it { is_expected.to include_recipe('cerner_splunk::_user_management') }

  context 'when .ui_login file exists' do
    let(:ui_login_exists) { true }

    it { is_expected.not_to touch_file('/opt/splunkforwarder/etc/.ui_login') }
  end

  context 'when .ui_login file does not exists' do
    let(:ui_login_exists) { false }

    it { is_expected.to touch_file('/opt/splunkforwarder/etc/.ui_login') }
  end

  it { is_expected.to include_recipe('cerner_splunk::_configure') }
end
