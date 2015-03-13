# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_apps' do
  subject do
    runner = ChefSpec::SoloRunner.new
    runner.converge(described_recipe)
  end

  it { is_expected.to_not be_nil }
end
