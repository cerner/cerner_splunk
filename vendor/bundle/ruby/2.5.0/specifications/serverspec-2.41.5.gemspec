# -*- encoding: utf-8 -*-
# stub: serverspec 2.41.5 ruby lib

Gem::Specification.new do |s|
  s.name = "serverspec".freeze
  s.version = "2.41.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gosuke Miyashita".freeze]
  s.date = "2019-08-18"
  s.description = "RSpec tests for your servers configured by Puppet, Chef, Itamae or anything else".freeze
  s.email = ["gosukenator@gmail.com".freeze]
  s.executables = ["serverspec-init".freeze]
  s.files = ["bin/serverspec-init".freeze]
  s.homepage = "http://serverspec.org/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.5".freeze
  s.summary = "RSpec tests for your servers configured by Puppet, Chef, Itamae or anything else".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_runtime_dependency(%q<rspec-its>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<specinfra>.freeze, ["~> 2.72"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.1.1"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<specinfra>.freeze, ["~> 2.72"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.1.1"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<specinfra>.freeze, ["~> 2.72"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.1.1"])
  end
end
