# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_install' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.set['splunk']['cmd'] = 'splunk'
      # node.set['splunk']['user'] = 'splunk
      node.set['splunk']['package']['type'] = 'universal_forwarder'
      node.set['splunk']['package']['base_name'] = 'splunkforwarder'
      node.set['splunk']['package']['download_group'] = 'universalforwarder'
      node.set['splunk']['package']['file_suffix'] = '.txt'
      node.set['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
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
  let(:platform_version) { '7.2' }

  let(:initd_exists) { nil }
  let(:ui_login_exists) { nil }
  let(:ftr_exists) { nil }
  let(:glob) { [] }

  let(:windows) { nil }

  let(:splunk_file) { 'splunkforwarder-6.5.2-67571ef4b87d' }
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
    allow(Dir).to receive(:glob).with('/opt/splunkforwarder/splunkforwarder-6.5.2-67571ef4b87d-*').and_return(glob)

    # Stub alt separator for windows in Ruby 1.9.3
    stub_const('::File::ALT_SEPARATOR', '/')
  end

  after do
    CernerSplunk.reset
  end

  it 'includes default chef-vault recipe' do
    expect(subject).to include_recipe('chef-vault::default')
  end

  it 'includes cerner_splunk::_cleanup_aeon recipe' do
    expect(subject).to include_recipe('cerner_splunk::_cleanup_aeon')
  end

  it 'includes cerner_splunk::_restart_prep recipe' do
    expect(subject).to include_recipe('cerner_splunk::_restart_prep')
  end

  let(:expected_properties) do
    {
      package: :universal_forwarder,
      version: '6.3.7',
      build: '8bf976cd6a7c',
      user: 'splunk',
      base_url: 'https://download.splunk.com/products'
    }
  end

  it 'installs splunk' do
    expect(subject).to install_splunk('splunk').with(expected_properties)
  end

  it 'initializes the splunk service' do
    expect(subject).to init_splunk_service('universal_forwarder').with(
      package: expected_properties[:package],
      user: expected_properties[:user],
      ulimit: 8192
    )
  end

  it 'notifies the ruby block "read splunk.secret"' do
    expect(subject.splunk_service('universal_forwarder')).to notify('ruby_block[read splunk.secret]').to(:run).immediately
  end

  context 'when platform is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }
    let(:windows) { true }
    let(:expected_properties) do
      {
        package: :universal_forwarder,
        version: '6.3.7',
        build: '8bf976cd6a7c',
        user: 'SYSTEM',
        base_url: 'https://download.splunk.com/products'
      }
    end

    before do
      ENV['PROGRAMW6432'] = 'test'
    end

    it 'installs splunk' do
      expect(subject).to install_splunk('splunk').with(expected_properties)
    end

    it 'initializes the splunk service' do
      expect(subject).to init_splunk_service('universal_forwarder').with(
        package: expected_properties[:package],
        user: expected_properties[:user]
      )
    end
  end

  it 'includes cerner_splunk::_configure_secret recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_secret')
  end

  it 'creates external config directory' do
    expected_attrs = {
      owner: 'splunk',
      group: 'splunk',
      mode: '0700'
    }
    expect(subject).to create_directory('/etc/splunk').with(expected_attrs)
  end

  it 'creates introspection log directory' do
    expected_attrs = {
      owner: 'splunk',
      group: 'splunk',
      mode: '0700'
    }
    expect(subject).to create_directory('/opt/splunkforwarder/var/log/introspection').with(expected_attrs)
  end

  it 'includes cerner_splunk::_user_management recipe' do
    expect(subject).to include_recipe('cerner_splunk::_user_management')
  end

  context 'when .ui_login file exists' do
    let(:ui_login_exists) { true }

    it 'does not touch .ui_login file' do
      expect(subject).to_not touch_file('/opt/splunkforwarder/etc/.ui_login')
    end
  end

  context 'when .ui_login file does not exists' do
    let(:ui_login_exists) { false }

    it 'touches .ui_login file' do
      expect(subject).to touch_file('/opt/splunkforwarder/etc/.ui_login')
    end
  end

  it 'includes cerner_splunk::_configure recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure')
  end
end
