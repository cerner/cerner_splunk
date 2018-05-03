# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_install' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['cmd'] = 'splunk'
      node.override['splunk']['user'] = 'splunk'
      node.override['splunk']['package']['base_name'] = 'splunkforwarder'
      node.override['splunk']['package']['download_group'] = 'universalforwarder'
      node.override['splunk']['package']['file_suffix'] = '.txt'
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
      'indexes' => 'cerner_splunk/indexes'
    }
  end

  let(:platform) { 'centos' }
  let(:platform_version) { '6.8' }

  let(:initd_exists) { nil }
  let(:ui_login_exists) { nil }
  let(:ftr_exists) { nil }
  let(:glob) { [] }

  let(:windows) { nil }

  let(:splunk_file) { 'splunkforwarder-7.0.3-fa31da744b51' }
  let(:splunk_filepath) { "/var/chef/cache/#{splunk_file}.txt" }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    allow(Chef::Recipe).to receive(:platform_family?).with('windows').and_return(windows)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/etc/init.d/splunk').and_return(initd_exists)
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/etc/.ui_login').and_return(ui_login_exists)
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/ftr').and_return(ftr_exists)

    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/opt/splunkforwarder/splunkforwarder-7.0.3-fa31da744b51-*').and_return(glob)

    # Stub alt separator for windows in Ruby 1.9.3
    stub_const('::File::ALT_SEPARATOR', '/')
  end

  after do
    CernerSplunk.reset
  end

  it 'includes cerner_splunk::_restart_marker recipe' do
    expect(subject).to include_recipe('cerner_splunk::_restart_marker')
  end

  it 'does nothing with the splunk service and notifies the deletion of the splunk file marker immediately' do
    splunk_service = subject.service('splunk')
    expect(splunk_service).to do_nothing
    expect(splunk_service).to notify('file[splunk-marker]').to(:delete).immediately
  end

  it 'does nothing with the splunk-restart service and notifies the deletion of the splunk file marker immediately' do
    splunk_restart_service = subject.service('splunk-restart')
    expect(splunk_restart_service).to do_nothing
    expect(splunk_restart_service).to notify('file[splunk-marker]').to(:delete).immediately
  end

  it 'runs ruby block splunk-delayed-restart' do
    expect(subject).to run_ruby_block('splunk-delayed-restart')
    expect(subject.ruby_block('splunk-delayed-restart')).to notify('service[splunk-restart]').to(:restart)
  end

  context 'when remote file has missing manifest' do
    let(:glob) { [] }

    it 'downloads the remote file' do
      expect(subject).to create_remote_file(splunk_filepath)
    end

    it 'does not delete the downloaded splunk package' do
      expect(subject).to_not delete_file(splunk_filepath)
    end

    context 'when platform is windows' do
      let(:platform) { 'windows' }
      let(:platform_version) { '2012R2' }
      let(:windows) { true }

      before do
        ENV['PROGRAMW6432'] = 'test'
      end

      it 'installs downloaded splunk package' do
        expected_attrs = {
          source: splunk_filepath,
          provider: Chef::Provider::Package::Windows,
          options: %(AGREETOLICENSE=Yes SERVICESTARTTYPE=auto LAUNCHSPLUNK=0 INSTALLDIR="test\\splunkforwarder")
        }
        if Chef::VERSION.slice(0..1) == '11'
          expect(subject).to install_windows_package('splunkforwarder').with(expected_attrs)
        else
          expect(subject).to install_package('splunkforwarder').with(expected_attrs)
        end
      end
    end

    context 'when platform is rhel' do
      let(:platform) { 'centos' }
      let(:platform_version) { '6.6' }

      it 'installs downloaded splunk package and notifies splunk-first-run' do
        expected_attrs = {
          source: splunk_filepath,
          provider: Chef::Provider::Package::Rpm
        }
        expect(subject).to install_package('splunkforwarder').with(expected_attrs)
      end
    end

    context 'when platform is debian' do
      let(:platform) { 'ubuntu' }
      let(:platform_version) { '14.04' }

      it 'installs downloaded splunk package and notifies splunk-first-run' do
        expected_attrs = {
          source: splunk_filepath,
          provider: Chef::Provider::Package::Dpkg
        }
        expect(subject).to install_package('splunkforwarder').with(expected_attrs)
      end
    end
  end

  context 'when remote file has manifest' do
    let(:glob) { [1] }

    it 'does not download the remote file' do
      expect(subject).to_not create_remote_file(splunk_filepath)
    end

    it 'does not install downloaded splunk package' do
      expect(subject).to_not install_package('splunkforwarder')
    end

    it 'deletes the downloaded splunk package' do
      expect(subject).to delete_file(splunk_filepath)
    end
  end

  it 'includes cerner_splunk::_configure_secret recipe' do
    expect(subject).to include_recipe('cerner_splunk::_configure_secret')
  end

  context 'when ftr file exists' do
    let(:ftr_exists) { true }

    it 'executes splunk-first-run' do
      expect(subject).to run_execute('splunk-first-run')
    end
  end

  context 'when ftr file does not exist' do
    let(:ftr_exists) { false }

    it 'does not execute splunk-first-run' do
      expect(subject).not_to run_execute('splunk-first-run')
    end
  end

  it 'runs ruby block read splunk.secret' do
    expect(subject).to run_ruby_block('read splunk.secret')
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
