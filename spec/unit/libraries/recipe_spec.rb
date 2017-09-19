
# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../../libraries/recipe'

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
end
