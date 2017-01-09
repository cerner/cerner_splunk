# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_migrate_forwarder' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['package']['base_name'] = 'splunk'
    end
    runner.converge(described_recipe)
  end

  let(:platform) { 'centos' }
  let(:platform_version) { '6.8' }

  it 'stops splunk service' do
    expect(subject).to stop_service('splunk').with(service_name: 'splunk')
  end

  it 'runs backup-splunk-artifacts ruby block' do
    expect(subject).to run_ruby_block('backup-splunk-artifacts')
  end

  context 'when platform family is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }

    let(:programw6432) { 'C:/home' }

    before do
      ENV['PROGRAMW6432'] = programw6432

      # Stub alt separator for windows in Ruby 1.9.3
      stub_const('::File::ALT_SEPARATOR', '/')
    end

    it 'deletes the splunk home directory' do
      expect(subject).to delete_directory(::File.join(programw6432, 'splunkforwarder'))
    end
  end

  context 'when platform family is linux' do
    let(:platform) { 'centos' }
    let(:platform_version) { '6.6' }

    it 'deletes the splunk home directory' do
      expect(subject).to delete_directory('/opt/splunkforwarder')
    end
  end

  it 'removes splunk package with opposite package name' do
    expect(subject).to remove_package('splunkforwarder')
  end
end
