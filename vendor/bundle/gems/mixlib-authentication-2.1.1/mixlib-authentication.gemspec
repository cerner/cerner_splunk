$:.unshift(File.dirname(__FILE__) + "/lib")
require "mixlib/authentication/version"

Gem::Specification.new do |s|
  s.name = "mixlib-authentication"
  s.version = Mixlib::Authentication::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Mixes in simple per-request authentication"
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Chef Software, Inc."
  s.email = "info@chef.io"
  s.homepage = "https://www.chef.io"

  s.require_path = "lib"
  s.files = %w{LICENSE README.md Gemfile Rakefile NOTICE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  %w{rspec-core rspec-expectations rspec-mocks}.each { |gem| s.add_development_dependency gem, "~> 3.2" }
  s.add_development_dependency "chefstyle"
  s.add_development_dependency "rake", "~> 11"
end
