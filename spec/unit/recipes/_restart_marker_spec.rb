# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_restart_marker' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8')
    runner.converge(described_recipe)
  end

  before do
    allow(CernerSplunk).to receive(:restart_marker_file).and_return('/foo/bar')
  end

  it 'does nothing with the splunk marker file' do
    expect(subject.file('splunk-marker')).to do_nothing
  end
end
