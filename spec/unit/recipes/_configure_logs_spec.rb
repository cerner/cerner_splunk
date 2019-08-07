# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_logs' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.10') do |node|
      node.override['splunk']['logs'] = logs
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:logs) do
    {
      'splunkd' => {
        'appender.metrics.maxFileSize' => '10000',
        'appender.metrics.maxBackupIndex' => '3'
      }
    }
  end

  it { is_expected.to_not be_nil }

  it 'installs the app with the expected attributes' do
    expected_attributes = {
      stanzas: {
        'splunkd' => {
          'appender.metrics.maxFileSize' => '10000',
          'appender.metrics.maxBackupIndex' => '3'
        }
      }
    }
    expect(subject).to create_splunk_template('/etc/log-local.cfg').with(expected_attributes)
  end
end
