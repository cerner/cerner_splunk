# coding: UTF-8

require_relative '../spec_helper'
require 'unit_converter'

describe 'unit_converter' do
  subject { CernerSplunk.convert_to_bytes(size) }

  context 'when size specified in TB' do
    let(:size) { '2TB' }
    it { is_expected.to eq(2_199_023_255_552) }
  end

  context 'when size specified in MB' do
    let(:size) { '2MB' }
    it { is_expected.to eq(2_097_152) }
  end

  context 'when size specified in KB' do
    let(:size) { '2KB' }
    it { is_expected.to eq(2048) }
  end

  context 'when size specified in B' do
    let(:size) { '2048B' }
    it { is_expected.to eq(2048) }
  end

  context 'when size has no unit specified' do
    let(:size) { '2048' }
    it { is_expected.to eq(2048) }
  end

  context 'when unit has one letter' do
    let(:size) { '2K' }
    it { is_expected.to eq(2048) }
  end

  context 'when unit has three letters' do
    let(:size) { '2KiB' }
    it { is_expected.to eq(2048) }
  end

  context 'when input has space between size and unit' do
    let(:size) { '2 KB' }
    it { is_expected.to eq(2048) }
  end

  context 'when input has more than one space' do
    let(:size) { ' 2 KB ' }
    it { is_expected.to eq(2048) }
  end

  context 'when size is in lower case' do
    let(:size) { '2kb' }
    it { is_expected.to eq(2048) }
  end

  context 'when size is in upper case' do
    let(:size) { '2KIB' }
    it { is_expected.to eq(2048) }
  end

  context 'when size is a decimal' do
    let(:size) { '2.5KB' }
    it { is_expected.to eq(2560) }
  end

  context 'when size is a decimal, less than 1 and greater then zero' do
    let(:size) { '0.5KB' }
    it { is_expected.to eq(512) }
  end

  context 'when size is a decimal and ones place is nil' do
    let(:size) { '.5KB' }
    it { expect { subject }.to raise_error('Unparsable size input .5KB') }
  end

  context 'when size has an invalid unit' do
    let(:size) { '5mk' }
    it { expect { subject }.to raise_error('Unparsable size input 5mk') }
  end

  context 'when size only has invalid unit and no numeric value' do
    let(:size) { 'invalidunit' }
    it { expect { subject }.to raise_error('Unparsable size input invalidunit') }
  end

  context 'when input size is empty' do
    let(:size) { '' }
    it { expect { subject }.to raise_error('Unparsable size input ') }
  end
end
