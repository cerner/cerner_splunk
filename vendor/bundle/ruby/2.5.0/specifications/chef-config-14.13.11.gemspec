# -*- encoding: utf-8 -*-
# stub: chef-config 14.13.11 ruby lib

Gem::Specification.new do |s|
  s.name = "chef-config".freeze
  s.version = "14.13.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Jacob".freeze]
  s.date = "2019-05-30"
  s.email = ["adam@chef.io".freeze]
  s.homepage = "https://github.com/chef/chef".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "2.7.5".freeze
  s.summary = "Chef's default configuration and config loading".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
      s.add_runtime_dependency(%q<mixlib-config>.freeze, ["< 4.0", ">= 2.2.12"])
      s.add_runtime_dependency(%q<fuzzyurl>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<tomlrb>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
    else
      s.add_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
      s.add_dependency(%q<mixlib-config>.freeze, ["< 4.0", ">= 2.2.12"])
      s.add_dependency(%q<fuzzyurl>.freeze, [">= 0"])
      s.add_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_dependency(%q<tomlrb>.freeze, ["~> 1.2"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
    end
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
    s.add_dependency(%q<mixlib-config>.freeze, ["< 4.0", ">= 2.2.12"])
    s.add_dependency(%q<fuzzyurl>.freeze, [">= 0"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
    s.add_dependency(%q<tomlrb>.freeze, ["~> 1.2"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-core>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.2"])
  end
end
