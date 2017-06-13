
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_migrate_forwarder' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.8') do |node|
      node.override['splunk']['package']['base_name'] = 'splunk'
    end
    runner.converge(described_recipe)
  end

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
