
# frozen_string_literal: true

# TODO: Whats this
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'libraries'))
require 'rspec'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef-vault'

RSpec.configure do |config|
  config.color = true
  config.formatter = 'documentation'
  config.order = 'rand'
  config.file_cache_path = '/var/chef/cache'
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.platform = 'redhat'
  config.version = '7.1'
end

module CernerSplunk
  # Need a way to reset the cached module level variables between specs
  def self.reset
    @my_cluster_data = nil
    @all_cluster_data = nil
  end
end
