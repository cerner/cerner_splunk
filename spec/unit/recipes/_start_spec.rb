# frozen_string_literal: true

require_relative '../spec_helper'

describe 'cerner_splunk::_start' do
  subject do
    runner = ChefSpec::SoloRunner.new(platform: platform, version: platform_version) do |node|
      node.override['splunk']['cmd'] = 'splunk'
      node.override['splunk']['user'] = 'splunk'
      node.override['splunk']['config']['clusters'] = ['cerner_splunk/cluster']
      node.override['splunk']['package']['version'] = package_version
    end
    # Have to include forwarder recipe so that _start recipe can send notifications to services
    runner.converge('cerner_splunk::forwarder', described_recipe)
  end

  let(:package_version) { '8.1.3' }

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
  let(:password_databag) { nil }

  let(:platform) { 'centos' }
  let(:platform_version) { '6.10' }
  let(:windows) { nil }

  before do
    allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
    stub_data_bag_item('cerner_splunk', 'cluster').and_return(cluster_config)
    stub_data_bag_item('cerner_splunk', 'indexes').and_return({})
    allow(Chef::Recipe).to receive(:platform_family?).with('windows').and_return(windows)
  end

  after do
    CernerSplunk.reset
  end

  context 'when platform is windows' do
    let(:platform) { 'windows' }
    let(:platform_version) { '2012R2' }
    let(:windows) { true }
    let(:password_databag) { 'cerner_splunk/passwords:winpass' }

    before do
      ENV['PROGRAMW6432'] = 'test'
      allow(ChefVault::Item).to receive(:data_bag_item_type).and_return(:normal)
      stub_data_bag_item('cerner_splunk', 'passwords').and_return('winpass' => 'foobar')
    end

    it 'does not execute boot-start script' do
      expect(subject).not_to run_execute('splunk enable boot-start -user splunk')
    end

    it 'does not insert ulimit into init.d script' do
      expect(subject).not_to run_ruby_block('update-initd-file')
    end

    it 'does not run restart-splunk-for-initd-ulimit ruby block' do
      expect(subject).not_to run_ruby_block('restart-splunk-for-initd-ulimit')
    end
  end

  context 'when platform is not windows' do
    let(:windows) { false }
    let(:initd_exists) { [false, false] }
    let(:systemd_exists) { [false, false] }
    let(:lines) { [] }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/etc/init.d/splunk').exactly(2).times.and_return(initd_exists[0], initd_exists[1])
      allow(File).to receive(:exist?).with('/etc/systemd/system/splunk.service').exactly(4).times.and_return(systemd_exists[0], systemd_exists[0], systemd_exists[1], systemd_exists[1])

      allow(File).to receive(:readlines).and_call_original
      allow(File).to receive(:readlines).with('/etc/init.d/splunk').and_return(lines)
    end

    context 'and platform version is 6.x' do
      let(:platform_version) { '6.10' }

      it 'executes boot-start script for initd' do
        expect(subject).to run_execute('splunk enable boot-start -user splunk -group splunk -systemd-managed 0')
      end

      context 'when init.d script does not exist' do
        let(:initd_exists) { [false, true] }

        it 'inserts ulimit into init.d script' do
          expect(subject).to run_ruby_block('update-initd-file')
        end

        it 'notifies the touch restart-marker resource' do
          expect(subject).to run_ruby_block('restart-splunk-for-initd-ulimit')
          expect(subject.ruby_block('restart-splunk-for-initd-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
        end
      end

      context 'when init.d script does exist' do
        let(:initd_exists) { [true, true] }

        it 'inserts ulimit into init.d script' do
          expect(subject).to run_ruby_block('update-initd-file')
        end

        context 'when ulimit is not present in init.d script beforehand' do
          let(:lines) { ['line 1', 'line 2'] }

          it 'notifies the touch restart-marker resource' do
            expect(subject).to run_ruby_block('restart-splunk-for-initd-ulimit')
            expect(subject.ruby_block('restart-splunk-for-initd-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
          end
        end

        context 'when ulimit is present in init.d script' do
          context 'and ulimit command is same as the one to be added' do
            let(:lines) { ['line 1', 'ulimit -n 8192'] }

            it 'does not run restart-splunk-for-initd-ulimit ruby block' do
              expect(subject).not_to run_ruby_block('restart-splunk-for-initd-ulimit')
            end
          end

          context 'and ulimit command is different than the one to be added' do
            let(:lines) { ['line 1', 'ulimit -n 1234'] }

            it 'notifies the touch restart-marker resource' do
              expect(subject).to run_ruby_block('restart-splunk-for-initd-ulimit')
              expect(subject.ruby_block('restart-splunk-for-initd-ulimit')).to notify('file[splunk-marker]').to(:touch).immediately
            end
          end
        end
      end
    end

    context 'and platform version is 7.x' do
      let(:platform_version) { '7.8.2003' }

      context 'and the splunk version is less than 8.0.0' do
        let(:package_version) { '7.2.10' }

        context 'when systemd script does not exist' do
          let(:systemd_exists) { [false, true] }

          it 'executes boot-start script for systemd' do
            expect(subject).to run_execute('splunk enable boot-start -user splunk -systemd-managed 1 -systemd-unit-file-name splunk')
          end

          it 'modifies the systemd file' do
            expect(subject).to edit_filter_lines('update-systemd-file')
          end

          it 'executes systemctl reload' do
            expect(subject.filter_lines('update-systemd-file')).to notify('execute[reload-systemctl]').to(:run).immediately
          end
        end

        context 'when systemd script already exists' do
          let(:systemd_exists) { [true, true] }

          it 'does not execute boot-start script for systemd' do
            expect(subject).not_to run_execute('splunk enable boot-start -user splunk -group splunk -systemd-managed 1 -systemd-unit-file-name splunk')
          end

          it 'modifies the systemd file' do
            expect(subject).to edit_filter_lines('update-systemd-file')
            expect(subject.filter_lines('update-systemd-file')).to notify('execute[reload-systemctl]').to(:run).immediately
          end
        end
      end

      context 'and the splunk version is greater than 8.0.0' do
        context 'when systemd script does not exist' do
          let(:systemd_exists) { [false, true] }

          it 'executes boot-start script for systemd' do
            expect(subject).to run_execute('splunk enable boot-start -user splunk -group splunk -systemd-managed 1 -systemd-unit-file-name splunk')
          end

          it 'does not modify the systemd file' do
            expect(subject).not_to edit_filter_lines('update-systemd-file')
          end

          it 'executes systemctl reload' do
            expect(subject.filter_lines('update-systemd-file')).to notify('execute[reload-systemctl]').to(:run).immediately
          end
        end

        context 'when systemd script already exists' do
          let(:systemd_exists) { [true, true] }

          it 'does not execute boot-start script for systemd' do
            expect(subject).not_to run_execute('splunk enable boot-start -user splunk -group splunk -systemd-managed 1 -systemd-unit-file-name splunk')
          end

          it 'does not modify the systemd file' do
            expect(subject).not_to edit_filter_lines('update-systemd-file')
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
