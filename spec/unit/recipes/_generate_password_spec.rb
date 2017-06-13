
# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_generate_password' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: 'redhat', version: '6.8') do |node|
      node.override['splunk']['node_type'] = node_type
      node.override['splunk']['config']['password_secrets'] = password_secrets
    end
    runner.converge(described_recipe)
  end

  let(:node_type) { :server }

  context 'when the vault item is configured for the current node' do
    let(:password_secrets) { { 'server' => 'cerner_splunk/admin_password' } }
    let(:expected_params) do
      {
        vault_bag: 'cerner_splunk',
        vault_item: 'admin_password',
        password_file_path: '/etc/splunk/password'
      }
    end
    it { is_expected.to regenerate_splunk_admin_password('change the splunk admin password').with expected_params }
  end

  context 'when the vault item is not configured for the current node' do
    let(:password_secrets) { { 'anotherserver' => 'cerner_splunk/admin_password' } }
    let(:expected_params) do
      {
        password_file_path: '/etc/splunk/password'
      }
    end
    it { is_expected.to regenerate_splunk_admin_password('change the splunk admin password').with expected_params }

    shared_examples_for 'search head cluster member without vault item' do
      it 'fails the chef run' do
        expect { subject }.to raise_error("You must configure a vault item for this search head cluster's admin password")
      end
    end

    context 'when the node is a search head cluster member' do
      it_should_behave_like 'search head cluster member without vault item' do
        let(:node_type) { :shc_search_head }
      end
    end

    context 'when the node is a search head cluster captain' do
      it_should_behave_like 'search head cluster member without vault item' do
        let(:node_type) { :shc_captain }
      end
    end
  end
end
