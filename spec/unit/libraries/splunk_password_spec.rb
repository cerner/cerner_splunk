# coding: UTF-8

require_relative '../spec_helper'
require 'splunk_password'
require 'rc4'

describe 'CernerSplunk::splunk_password' do
  let(:splunk_secret) { 'qYFEHts8G0E/ABbp' }
  let(:password) { 'password' }

  describe '.splunk_encrypt_password' do
    context 'when the password has already been encrypted' do
      let(:password) { '$1$RhLQiUyG3Qc7' }

      it 'does not re-encrypt it again' do
        encrypted = CernerSplunk.splunk_encrypt_password(password, splunk_secret)
        expect(encrypted).to eq(password)
      end
    end
  end

  describe '.splunk_decrypt_password' do
    context 'when decrypting an encrypted password' do
      subject { CernerSplunk.splunk_encrypt_password(password, splunk_secret) }
      let(:decrypted_password) { CernerSplunk.splunk_decrypt_password(subject, splunk_secret) }

      it 'results in the original value' do
        expect(decrypted_password).to eq(password)
      end
    end

    context 'when decrypting an encrypted sslconfig password' do
      subject { CernerSplunk.splunk_encrypt_password(password, splunk_secret, false) }
      let(:decrypted_password) { CernerSplunk.splunk_decrypt_password(subject, splunk_secret, false) }

      it 'results in the original value' do
        expect(decrypted_password).to eq(password)
      end
    end
  end
end
