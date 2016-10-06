# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_migrate_forwarder' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.set['splunk']['package']['base_name'] = 'splunk'
    end
    runner.converge(described_recipe)
  end

  let(:platform) { 'redhat' }
  let(:platform_version) { '7.2' }

  it 'stops splunk service' do
    expect(subject).to stop_splunk_service('stop old service').with(package: :universal_forwarder)
  end

  it 'runs backup-splunk-artifacts ruby block' do
    expect(subject).to run_ruby_block('backup-splunk-artifacts')
  end

  it 'uninstalls splunk' do
    expect(subject).to uninstall_splunk('uninstall old splunk').with(package: :universal_forwarder)
  end
end
