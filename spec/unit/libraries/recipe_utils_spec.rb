# frozen_string_literal: true

require_relative '../spec_helper'
require 'recipe_utils'
require 'splunk_app'

describe 'CernerSplunk' do
  describe '.validate_secret_file' do
    let(:file_location) { '/opt/splunk/etc/auth/splunk.secret' }
    let(:configured_secret) { 'ThisIsMySplunkSecret' }
    subject { CernerSplunk.validate_secret_file(file_location, configured_secret) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/opt/splunk/etc/auth/splunk.secret').and_return(file_exists)
    end

    context 'when the splunk.secret file exists' do
      let(:file_exists) { true }

      before do
        allow(File).to receive(:open).with(file_location, 'r').and_return(secret_file_contents)
      end

      context 'with a different value than what is configured' do
        let(:secret_file_contents) { 'different_value' }

        it 'raises an error' do
          message = 'The splunk.secret file already exists with a different value. Modification of that file is not currently supported.'
          expect { subject }.to raise_error(RuntimeError, message)
        end
      end

      context 'with the same value as what is configured' do
        let(:secret_file_contents) { configured_secret }

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context "when the splunk.secret file doesn't exist" do
      let(:file_exists) { false }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '.my_cluster_data' do
    before do
      allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:vault)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'cluster_bag').and_return(cluster_configs)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'multisite_bag').and_return(multisite_configs)
    end

    after do
      CernerSplunk.reset
    end

    let(:clusters) { ['cerner_splunk/cluster_bag'] }
    let(:node) { { 'splunk' => { 'config' => { 'clusters' => clusters } } } }
    let(:cluster_configs) { { 'site' => 'site1', 'multisite' => 'cerner_splunk/multisite_bag', 'apps' => 'cerner_splunk/apps', 'indexes' => 'cerner_splunk/overridden-indexes' } }
    let(:multisite_configs) { { 'sites' => ['cerner_splunk/cluster_bag'], 'master_uri' => 'https://33.33.33.11:8089', 'indexes' => 'cerner_splunk/indexes' } }

    subject { CernerSplunk.my_cluster_data(node) }

    context 'cluster is a multisite cluster' do
      it 'merges multisite and cluster attributes' do
        expected_attributes = {
          'sites' => ['cerner_splunk/cluster_bag'],
          'master_uri' => 'https://33.33.33.11:8089',
          'site' => 'site1',
          'multisite' => 'cerner_splunk/multisite_bag',
          'indexes' => 'cerner_splunk/overridden-indexes',
          'apps' => 'cerner_splunk/apps'
        }
        expect(subject).to eq(expected_attributes)
      end
    end

    context 'cluster is a singlesite cluster' do
      let(:cluster_configs) { { 'master_uri' => 'https://33.33.33.11:8089', 'replication_ports' => { '8080' => {} }, 'receivers' => ['33.33.33.33'] } }

      it 'only returns the cluster config' do
        expected_attributes = {
          'receivers' => ['33.33.33.33'],
          'master_uri' => 'https://33.33.33.11:8089',
          'replication_ports' => { '8080' => {} }
        }
        expect(subject).to eq(expected_attributes)
      end
    end
  end

  describe '.all_clusters_data' do
    before do
      allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:vault)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'cluster_bag1').and_return(cluster_configs1)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'multisite_bag1').and_return(multisite_configs1)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'cluster_bag2').and_return(cluster_configs2)
      allow(ChefVault::Item).to receive(:load).with('cerner_splunk', 'multisite_bag2').and_return(multisite_configs2)
    end

    after do
      CernerSplunk.reset
    end

    let(:clusters) { ['cerner_splunk/cluster_bag1', 'cerner_splunk/cluster_bag2'] }
    let(:node) { { 'splunk' => { 'config' => { 'clusters' => clusters } } } }
    let(:cluster_configs1) { { 'site' => 'site1', 'multisite' => 'cerner_splunk/multisite_bag1' } }
    let(:multisite_configs1) { { 'sites' => ['cerner_splunk/cluster_bag1'], 'master_uri' => 'https://33.33.33.11:8089', 'settings' => { 'pass4SymmKey' => 'my_key' } } }
    let(:cluster_configs2) { { 'site' => 'site2', 'multisite' => 'cerner_splunk/multisite_bag2' } }
    let(:multisite_configs2) { { 'sites' => ['cerner_splunk/cluster_bag2'], 'master_uri' => 'https://33.33.33.22:8089', 'settings' => { 'pass4SymmKey' => 'my_other_key' } } }

    subject { CernerSplunk.all_clusters_data(node) }

    context 'when there is only a single cluster' do
      let(:clusters) { ['cerner_splunk/cluster_bag1'] }

      it 'returns the cluster data' do
        expected_attributes = [
          {
            'sites' => ['cerner_splunk/cluster_bag1'],
            'master_uri' => 'https://33.33.33.11:8089',
            'site' => 'site1',
            'multisite' => 'cerner_splunk/multisite_bag1',
            'settings' => {
              'pass4SymmKey' => 'my_key'
            }
          }
        ]
        expect(subject).to eq(expected_attributes)
      end
    end

    context 'when there are multiple multisite clusters' do
      it 'returns the multisite data for all clusters' do
        expected_attributes = [
          {
            'sites' => ['cerner_splunk/cluster_bag1'],
            'master_uri' => 'https://33.33.33.11:8089',
            'site' => 'site1',
            'multisite' => 'cerner_splunk/multisite_bag1',
            'settings' => {
              'pass4SymmKey' => 'my_key'
            }
          },
          {
            'sites' => ['cerner_splunk/cluster_bag2'],
            'master_uri' => 'https://33.33.33.22:8089',
            'site' => 'site2',
            'multisite' => 'cerner_splunk/multisite_bag2',
            'settings' => {
              'pass4SymmKey' => 'my_other_key'
            }
          }
        ]
        expect(subject).to eq(expected_attributes)
      end
    end

    context 'when there is a multisite cluster and a single site cluster' do
      let(:cluster_configs2) { { 'master_uri' => 'https://33.33.33.33:8089', 'settings' => { 'pass4SymmKey' => 'my_other_key' } } }

      it 'returns the multi and single site cluster attributes for all clusters' do
        expected_attributes = [
          {
            'sites' => ['cerner_splunk/cluster_bag1'],
            'master_uri' => 'https://33.33.33.11:8089',
            'site' => 'site1',
            'multisite' => 'cerner_splunk/multisite_bag1',
            'settings' => {
              'pass4SymmKey' => 'my_key'
            }
          },
          {
            'master_uri' => 'https://33.33.33.33:8089',
            'settings' => {
              'pass4SymmKey' => 'my_other_key'
            }
          }
        ]
        expect(subject).to eq(expected_attributes)
      end
    end

    context 'when there is a non-existent data bag configured' do
      let(:cluster_configs1) { nil }

      context 'as the first item in the array' do
        let(:clusters) { ['cerner_splunk/cluster_bag1', 'cerner_splunk/cluster_bag2'] }

        it 'handles the invalid cluster' do
          expected_attributes = [
            nil,
            {
              'sites' => ['cerner_splunk/cluster_bag2'],
              'master_uri' => 'https://33.33.33.22:8089',
              'site' => 'site2',
              'multisite' => 'cerner_splunk/multisite_bag2',
              'settings' => {
                'pass4SymmKey' => 'my_other_key'
              }
            }
          ]
          expect(subject).to eq(expected_attributes)
        end
      end

      context 'as the second item in the array' do
        let(:clusters) { ['cerner_splunk/cluster_bag2', 'cerner_splunk/cluster_bag1'] }

        it 'handles the invalid cluster' do
          expected_attributes = [
            {
              'sites' => ['cerner_splunk/cluster_bag2'],
              'master_uri' => 'https://33.33.33.22:8089',
              'site' => 'site2',
              'multisite' => 'cerner_splunk/multisite_bag2',
              'settings' => {
                'pass4SymmKey' => 'my_other_key'
              }
            },
            nil
          ]
          expect(subject).to eq(expected_attributes)
        end
      end
    end
  end

  describe '.multisite_cluster?' do
    let(:cluster) { 'site1' }
    let(:multisite) { {} }

    let(:bag) { { 'id' => 'site1', 'master_uri' => 'https://33.33.33.11:8089' }.merge(multisite) }

    subject { CernerSplunk.multisite_cluster?(bag, cluster) }

    context 'when multisite attribute is configured in the databag' do
      context 'when site attribute is specified in the databag' do
        let(:multisite) { { 'multisite' => 'cerner_splunk/site1', 'site' => 'site1' } }

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'when site attribute is not specified in the databag' do
        let(:multisite) { { 'multisite' => 'cerner_splunk/site1' } }

        it 'raises an error' do
          message = "'site' attribute not configured in the cluster databag: site1"
          expect { subject }.to raise_error(RuntimeError, message)
        end
      end
    end

    context 'when multisite attribute is not configured in the databag' do
      context 'when multisite attribute is nil' do
        it 'returns false' do
          expect(subject).to be false
        end
      end

      context 'when multisite attribute is empty' do
        let(:multisite) { { 'multisite' => '' } }
        it 'returns false' do
          expect(subject).to be false
        end
      end
    end
  end
end
