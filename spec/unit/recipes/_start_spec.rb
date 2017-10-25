# coding: UTF-8

require_relative '../spec_helper'

describe 'cerner_splunk::_start' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['cmd'] = 'splunk'
      node.override['splunk']['user'] = 'splunk'
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
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

  let(:platform) { 'centos' }
  let(:platform_version) { '6.8' }

  let(:lines) { [] }
  let(:exists) { nil }

  let(:windows) { nil }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    allow(Chef::Recipe).to receive(:platform_family?).with('windows').and_return(windows)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/etc/init.d/splunk').and_return(exists)
    allow(File).to receive(:readlines).and_call_original
    allow(File).to receive(:readlines).with('/etc/init.d/splunk').and_return(lines)

    # Stub alt separator for windows in Ruby 1.9.3
    stub_const('::File::ALT_SEPARATOR', '|')
  end

  after do
    CernerSplunk.reset
  end

  context 'when platform is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }
    let(:windows) { true }

    before do
      ENV['PROGRAMW6432'] = 'test'
    end

    it 'does not execute boot-start script' do
      expect(subject).to_not run_execute('splunk enable boot-start -user splunk')
    end

    it 'does not insert ulimit into init.d script' do
      expect(subject).to_not run_ruby_block('insert ulimit')
    end

    it 'does not run restart-splunk-for-ulimit ruby block' do
      expect(subject).not_to run_ruby_block('restart-splunk-for-ulimit')
    end
  end

  context 'when platform is not windows' do
    let(:platform) { 'centos' }
    let(:platform_version) { '6.6' }
    let(:windows) { false }

    it 'executes boot-start script' do
      expect(subject).to run_execute('splunk enable boot-start -user splunk')
    end

    it 'inserts ulimit into init.d script' do
      expect(subject).to run_ruby_block('insert ulimit')
    end

    context 'when init.d script does not exist' do
      let(:exists) { false }

      it 'notifies the touch restart-marker resource' do
        expect(subject).to run_ruby_block('restart-splunk-for-ulimit')
        expect(subject.ruby_block('restart-splunk-for-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
      end
    end

    context 'when init.d script does exist' do
      let(:exists) { true }

      context 'when ulimit is not present in init.d script' do
        let(:lines) { ['line 1', 'line 2'] }

        it 'inserts ulimit into init.d script' do
          expect(subject).to run_ruby_block('insert ulimit')
        end

        it 'notifies the touch restart-marker resource' do
          expect(subject).to run_ruby_block('restart-splunk-for-ulimit')
          expect(subject.ruby_block('restart-splunk-for-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
        end
      end

      context 'when ulimit is present in init.d script' do
        context 'when ulimit command is same as the one to be added' do
          let(:lines) { ['line 1', 'ulimit -n 8192'] }

          it 'inserts ulimit into init.d script' do
            expect(subject).to run_ruby_block('insert ulimit')
          end

          it 'does not run restart-splunk-for-ulimit ruby block' do
            expect(subject).not_to run_ruby_block('restart-splunk-for-ulimit')
          end
        end

        context 'when ulimit command is different than the one to be added' do
          let(:lines) { ['line 1', 'ulimit -n 1234'] }

          it 'inserts ulimit into init.d script' do
            expect(subject).to run_ruby_block('insert ulimit')
          end

          it 'notifies the touch restart-marker resource' do
            expect(subject).to run_ruby_block('restart-splunk-for-ulimit')
            expect(subject.ruby_block('restart-splunk-for-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
          end
        end
      end
    end
  end

  it 'notifies the start splunk resource' do
    expect(subject).to run_ruby_block('start-splunk')
    expect(subject.ruby_block('start-splunk')).to notify('service[splunk]').to(:start).immediately
  end
end
