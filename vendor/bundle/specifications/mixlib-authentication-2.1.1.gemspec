# -*- encoding: utf-8 -*-
# stub: mixlib-authentication 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mixlib-authentication".freeze
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chef Software, Inc.".freeze]
  s.date = "2018-06-01"
  s.description = "Mixes in simple per-request authentication".freeze
  s.email = "info@chef.io".freeze
  s.homepage = "https://www.chef.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Mixes in simple per-request authentication".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<chefstyle>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 11"])
    else
      s.add_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
      s.add_dependency(%q<chefstyle>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 11"])
    end
  else
    s.add_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
    s.add_dependency(%q<chefstyle>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 11"])
  end
end
