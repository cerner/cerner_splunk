# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_configure_indexes' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'centos', version: '6.10') do |node|
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

  context 'when _noGenerateTstatsHomePath is set to true or remotePath is set for specific indexes' do
    let(:index_config) do
      {
        'config' => {
          'volume:test' => {
            'path' => '/test/path'
          },
          'index_a' => { '_volume' => 'bar' },
          'index_b' => { '_volume' => 'test', '_noGenerateTstatsHomePath' => true },
          'index_c' => { '_volume' => 'test', 'remotePath' => 'volume:remote_store/$_index_name' }
        }
      }
    end

    it 'writes the indexes.conf file without tstatsHomePath only for those indexes' do
      expected_attributes = {
        stanzas: {
          'volume:test' => index_config['config']['volume:test'],
          'index_a' => {
            'coldPath' => 'volume:bar/index_a/colddb',
            'homePath' => 'volume:bar/index_a/db',
            'thawedPath' => '$SPLUNK_DB/index_a/thaweddb',
            'tstatsHomePath' => 'volume:bar/index_a/datamodel_summary'
          },
          'index_b' => {
            'coldPath' => 'volume:test/index_b/colddb',
            'homePath' => 'volume:test/index_b/db',
            'thawedPath' => '$SPLUNK_DB/index_b/thaweddb'
          },
          'index_c' => {
            'coldPath' => 'volume:test/index_c/colddb',
            'homePath' => 'volume:test/index_c/db',
            'thawedPath' => '$SPLUNK_DB/index_c/thaweddb',
            'remotePath' => 'volume:remote_store/$_index_name'
          }
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end

  context 'when _noGenerateTstatsHomePath is set to true in default stanza' do
    let(:index_config) do
      {
        'config' => {
          'default' => {
            '_noGenerateTstatsHomePath' => true,
            'remotePath' => 'volume:remote_store/$_index_name'
          },
          'volume:test' => {
            'path' => '/test/path'
          },
          'index_a' => { '_volume' => 'bar' },
          'index_b' => { '_volume' => 'test' },
          'index_c' => { '_volume' => 'test' }
        }
      }
    end

    it 'writes the indexes.conf file without tstats paths for all indexes' do
      expected_attributes = {
        stanzas: {
          'default' => { 'remotePath' => 'volume:remote_store/$_index_name' },
          'volume:test' => index_config['config']['volume:test'],
          'index_a' => {
            'coldPath' => 'volume:bar/index_a/colddb',
            'homePath' => 'volume:bar/index_a/db',
            'thawedPath' => '$SPLUNK_DB/index_a/thaweddb'
          },
          'index_b' => {
            'coldPath' => 'volume:test/index_b/colddb',
            'homePath' => 'volume:test/index_b/db',
            'thawedPath' => '$SPLUNK_DB/index_b/thaweddb'
          },
          'index_c' => {
            'coldPath' => 'volume:test/index_c/colddb',
            'homePath' => 'volume:test/index_c/db',
            'thawedPath' => '$SPLUNK_DB/index_c/thaweddb'
          }
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end

  context 'when remotePath is set in default stanza' do
    let(:index_config) do
      {
        'config' => {
          'default' => {
            'remotePath' => 'volume:remote_store/$_index_name'
          },
          'volume:test' => {
            'path' => '/test/path'
          },
          'index_a' => { '_volume' => 'bar' },
          'index_b' => { '_volume' => 'test' },
          'index_c' => { '_volume' => 'test' }
        }
      }
    end

    it 'writes the indexes.conf file without tstats paths for all indexes' do
      expected_attributes = {
        stanzas: {
          'default' => { 'remotePath' => 'volume:remote_store/$_index_name' },
          'volume:test' => index_config['config']['volume:test'],
          'index_a' => {
            'coldPath' => 'volume:bar/index_a/colddb',
            'homePath' => 'volume:bar/index_a/db',
            'thawedPath' => '$SPLUNK_DB/index_a/thaweddb'
          },
          'index_b' => {
            'coldPath' => 'volume:test/index_b/colddb',
            'homePath' => 'volume:test/index_b/db',
            'thawedPath' => '$SPLUNK_DB/index_b/thaweddb'
          },
          'index_c' => {
            'coldPath' => 'volume:test/index_c/colddb',
            'homePath' => 'volume:test/index_c/db',
            'thawedPath' => '$SPLUNK_DB/index_c/thaweddb'
          }
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end

  context 'when remotePath is set in default stanza and _maxDailyDataSizeMB is given' do
    let(:index_config) do
      {
        'config' => {
          'default' => {
            'remotePath' => 'volume:remote_store/$_index_name',
            '_maxDailyDataSizeMB' => 100
          },
          'index_a' => {
            '_maxDailyDataSizeMB' => 100
          },
          'index_b' => {
            '_maxDailyDataSizeMB' => 25
          }
        },
        'flags' => {
          'index_a' => { 'noGeneratePaths' => true },
          'index_b' => { 'noGeneratePaths' => true }
        }
      }
    end

    it 'writes the indexes.conf file with calculated maxGlobalDataSizeMB' do
      expected_attributes = {
        stanzas: {
          'default' => {
            'maxGlobalDataSizeMB' => 240_240,
            'remotePath' => 'volume:remote_store/$_index_name'
          },
          'index_a' => {
            'maxGlobalDataSizeMB' => 240_240
          },
          'index_b' => {
            'maxGlobalDataSizeMB' => 60_060
          }
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end

  context 'when remotePath is set in specific stanza and _maxDailyDataSizeMB is given' do
    let(:index_config) do
      {
        'config' => {
          'default' => {
            '_maxDailyDataSizeMB' => 100
          },
          'index_a' => {
            'remotePath' => 'volume:remote_store/$_index_name',
            '_maxDailyDataSizeMB' => 100
          },
          'index_b' => {
            '_maxDailyDataSizeMB' => 25
          }
        },
        'flags' => {
          'index_a' => { 'noGeneratePaths' => true },
          'index_b' => { 'noGeneratePaths' => true }
        }
      }
    end

    it 'writes the indexes.conf file with calculated maxGlobalDataSizeMB in specific index' do
      expected_attributes = {
        stanzas: {
          'default' => {
            'maxTotalDataSizeMB' => 160_160
          },
          'index_a' => {
            'maxGlobalDataSizeMB' => 240_240,
            'remotePath' => 'volume:remote_store/$_index_name'
          },
          'index_b' => {
            'maxTotalDataSizeMB' => 40_040
          }
        }
      }

      expect(subject).to create_splunk_template('system/indexes.conf').with(expected_attributes)
    end
  end
end
