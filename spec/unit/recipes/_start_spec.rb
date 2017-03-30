
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_start' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.set['splunk']['package']['type'] = 'splunk'
      node.set['splunk']['cmd'] = 'splunk'
      node.set['splunk']['user'] = 'splunk'
      node.set['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end
    # Have to include forwarder recipe so that _start recipe can send notifications to services
    runner.converge('cerner_splunk::forwarder', described_recipe)
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

  after do
    CernerSplunk.reset
  end
  
  let(:platform) { 'redhat' }
  let(:platform_version) { '7.2' }

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return({})
  end

  it 'notifies the start splunk resource' do
    expect(subject).to run_ruby_block('start-splunk')
    expect(subject.ruby_block('start-splunk')).to notify('splunk_service[splunk]').to(:start).immediately
  end
end
