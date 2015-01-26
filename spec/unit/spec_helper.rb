# coding: UTF-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'libraries'))
require 'rspec'

RSpec.configure do |config|
  config.order = 'random'
end
