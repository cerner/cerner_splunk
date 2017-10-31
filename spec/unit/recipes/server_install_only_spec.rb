# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::server_install_only' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8')
    runner.converge(described_recipe)
  end

  after do
    CernerSplunk.reset
  end

  it 'includes cerner_splunk::_install_server recipe' do
    expect(subject).to include_recipe('cerner_splunk::_install_server')
  end

  it 'includes cerner_splunk::_start recipe' do
    expect(subject).to include_recipe('cerner_splunk::_start')
  end

  it 'includes cerner_splunk::image_prep recipe' do
    expect(subject).to include_recipe('cerner_splunk::image_prep')
  end
end
