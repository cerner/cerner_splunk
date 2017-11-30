# coding: UTF-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'libraries'))
require 'rspec'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef-vault'
require 'conf_template'

RSpec.configure do |config|
  config.order = 'random'
  config.file_cache_path = '/var/chef/cache'
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

module CernerSplunk
  # Need a way to reset the cached module level variables between specs
  def self.reset
    @my_cluster_data = nil
    @all_cluster_data = nil
    @multisite_bag_data = nil
  end
end
