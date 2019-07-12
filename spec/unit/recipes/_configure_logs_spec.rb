# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_logs' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['logs'] = logs
    end
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:logs) do
    {
      'appender.metrics.maxFileSize' => '10000',
      'appender.metrics.maxBackupIndex' => '3'
    }
  end

  it { is_expected.to_not be_nil }

  it 'installs the app with the expected attributes' do
    expected_attributes = {
      contents: {
        'appender.metrics.maxFileSize' => '10000',
        'appender.metrics.maxBackupIndex' => '3'
      }
    }
    expect(subject).to create_splunk_logs('/opt/splunk/etc/log-local.cfg').with(expected_attributes)
  end
end
