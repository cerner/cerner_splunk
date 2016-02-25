# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_indexes' do
  subject do
    runner = ChefSpec::SoloRunner.new do |node|
      node.set['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end
    # Have to include marker recipe so that we can send notifications to its resources
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
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

  let(:index_config) do
    {
      'config' => {
        'volume:test' => {
          'path' => '/test/path'
        },
        'index_a' => { '_directory_name' => 'foo' },
        'index_b' => { '_volume' => 'test' }
      }
    }
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'cluster').and_return(cluster_config)
    allow(Chef::DataBagItem).to receive(:load).with('cerner_splunk', 'indexes').and_return(index_config)
  end

  after do
    CernerSplunk.reset
  end

  it 'writes the indexes.conf file' do
    expected_attributes = {
      stanzas: {
        'volume:test' => index_config['config']['volume:test'],
        'index_a' => {
          'coldPath' => '$SPLUNK_DB/foo/colddb',
          'homePath' => '$SPLUNK_DB/foo/db',
          'thawedPath' => '$SPLUNK_DB/foo/thaweddb'
        },
        'index_b' => {
          'coldPath' => 'volume:test/index_b/colddb',
          'homePath' => 'volume:test/index_b/db',
          'thawedPath' => '$SPLUNK_DB/index_b/thaweddb',
          'tstatsHomePath' => 'volume:test/index_b/datamodel_summary'
        }
      }
    }

    expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
  end
end
