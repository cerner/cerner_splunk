def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

BERKS_SPEC_DATA = File.expand_path("../data", __FILE__)

require "rspec"
require "cleanroom/rspec"
require "webmock/rspec"
require "rspec/its"

Dir["spec/support/**/*.rb"].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.include Berkshelf::RSpec::FileSystemMatchers
  config.include Berkshelf::RSpec::ChefAPI
  config.include Berkshelf::RSpec::ChefServer
  config.include Berkshelf::RSpec::Git
  config.include Berkshelf::RSpec::PathHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec
  config.filter_run focus: true
  config.filter_run_excluding not_supported_on_windows: windows?
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    Berkshelf.logger = Berkshelf::Logger.new(nil)
    Berkshelf.set_format(:null)
    Berkshelf.ui.mute!
  end

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: false, net_http_connect_on_start: true)
    Berkshelf::RSpec::ChefServer.start
  end

  config.before(:all) do
    ENV["BERKSHELF_PATH"] = berkshelf_path.to_s
  end

  config.before(:each) do
    clean_tmp_path
    Berkshelf.initialize_filesystem
    Berkshelf::CookbookStore.instance.initialize_filesystem
    reload_configs
  end
end

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

require "berkshelf"

module Berkshelf
  class GitLocation
    include Berkshelf::RSpec::Git

    alias :real_clone :clone
    def clone
      fake_remote = generate_fake_git_remote(uri, tags: @branch ? [@branch] : [])
      @uri = "file://#{fake_remote}"
      real_clone
    end
  end
end
