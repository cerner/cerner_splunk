# -*- encoding: utf-8 -*-
# stub: fauxhai-ng 9.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fauxhai-ng".freeze
  s.version = "9.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Seth Vargo".freeze, "Tim Smith".freeze]
  s.date = "2021-04-07"
  s.description = "Easily mock out ohai data".freeze
  s.email = ["sethvargo@gmail.com".freeze, "tsmith84@gmail.com".freeze]
  s.executables = ["fauxhai".freeze]
  s.files = ["bin/fauxhai".freeze]
  s.homepage = "https://github.com/chefspec/fauxhai".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "2.7.5".freeze
  s.summary = "Fauxhai provides an easy way to mock out your ohai data for testing with chefspec!".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<net-ssh>.freeze, [">= 0"])
      s.add_development_dependency(%q<chef>.freeze, [">= 13.0"])
      s.add_development_dependency(%q<ohai>.freeze, [">= 13.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.2"])
    else
      s.add_dependency(%q<net-ssh>.freeze, [">= 0"])
      s.add_dependency(%q<chef>.freeze, [">= 13.0"])
      s.add_dependency(%q<ohai>.freeze, [">= 13.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<rspec-its>.freeze, ["~> 1.2"])
    end
  else
    s.add_dependency(%q<net-ssh>.freeze, [">= 0"])
    s.add_dependency(%q<chef>.freeze, [">= 13.0"])
    s.add_dependency(%q<ohai>.freeze, [">= 13.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rspec-its>.freeze, ["~> 1.2"])
  end
end
