require_relative '../spec_helper'
require 'splunk_app'

describe 'CernerSplunk::SplunkApp.merge_hashes' do
  let(:one) { {} }
  let(:two) { {} }
  let(:three) { {} }
  subject { CernerSplunk::SplunkApp.merge_hashes(one, two, three) }

  context 'when given empty hashes' do
    it { is_expected.to eq({}) }
  end

  context 'when given different keys' do
    let(:one) { { foo: {} } }
    let(:two) { { bar: {} } }
    let(:three) { { baz: {} } }

    it { is_expected.to eq(foo: {}, bar: {}, baz: {}) }
  end

  context 'when given same keys' do
    let(:one) { { foo: { a: 'foo' } } }
    let(:two) { { foo: { a: 'bar' } } }
    let(:three) { { foo: { a: 'baz' } } }

    it { is_expected.to eq(foo: { a: 'baz' }) }
  end

  context 'when given a key with a non-hash value' do
    before { pending 'when issue #36 is fixed' }
    let(:one) { { foo: 'bar' } }

    it { is_expected.to eq({}) }
  end
end
