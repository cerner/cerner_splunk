# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_indexes' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.8') do |node|
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
    end
    # Have to include marker recipe so that we can send notifications to its resources
    runner.converge('cerner_splunk::_restart_marker', described_recipe)
  end

  let(:cluster_config) do
    {
      'receivers' => ['33.33.33.20'],
      'license_uri' => nil,
      'settings' => {
        'replication_factor' => 2,
        '_cerner_splunk_indexer_count' => 3
      },
      'receiver_settings' => {
        'splunktcp' => {
          'port' => '9997'
        }
      },
      'indexes' => 'cerner_splunk/indexes'
    }
  end

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return(index_config)
  end

  after do
    CernerSplunk.reset
  end

  context 'when volumes and directory names are configured' do
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

    it 'writes the indexes.conf file with the proper paths' do
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

  context 'when _maxDailyDataSizeMB is provided' do
    let(:index_config) do
      {
        'config' => {
          'default' => {
            '_maxDailyDataSizeMB' => 100,
            'frozenTimePeriodInSecs' => 2_592_000 # 30 days
          },
          'index_a' => {
            '_maxDailyDataSizeMB' => 100,
            'maxTotalDataSizeMB' => 1000
          },
          'index_b' => {
            '_maxDailyDataSizeMB' => 25
          },
          'index_c' => {
            '_maxDailyDataSizeMB' => 25,
            'frozenTimePeriodInSecs' => 86_400
          },
          'index_d' => {
            '_maxDailyDataSizeMB' => 100,
            '_dataSizePaddingPercent' => 25
          },
          'index_e' => {
            '_dataSizePaddingPercent' => 50
          }
        },
        'flags' => {
          'index_a' => { 'noGeneratePaths' => true },
          'index_b' => { 'noGeneratePaths' => true },
          'index_c' => { 'noGeneratePaths' => true },
          'index_d' => { 'noGeneratePaths' => true },
          'index_e' => { 'noGeneratePaths' => true }
        }
      }
    end

    it 'writes the indexes.conf file with calculated maxTotalDataSizeMB' do
      expected_attributes = {
        stanzas: {
          'default' => {
            'frozenTimePeriodInSecs' => 2_592_000,
            'maxTotalDataSizeMB' => 2200
          },
          'index_a' => {
            'maxTotalDataSizeMB' => 1000
          },
          'index_b' => {
            'maxTotalDataSizeMB' => 550
          },
          'index_c' => {
            'frozenTimePeriodInSecs' => 86_400,
            'maxTotalDataSizeMB' => 18
          },
          'index_d' => {
            'maxTotalDataSizeMB' => 2500
          },
          'index_e' => {}
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end
end
