# -*- encoding: utf-8 -*-
# stub: foodcritic 16.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "foodcritic".freeze
  s.version = "16.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Crump".freeze]
  s.date = "2020-06-22"
  s.description = "A code linting tool for Chef Infra cookbooks.".freeze
  s.executables = ["foodcritic".freeze]
  s.files = ["bin/foodcritic".freeze]
  s.homepage = "http://foodcritic.io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "foodcritic-16.3.0".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.5", "< 2.0"])
      s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<treetop>.freeze, ["~> 1.4"])
      s.add_runtime_dependency(%q<ffi-yajl>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<erubis>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rufus-lru>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<cucumber-core>.freeze, [">= 1.3", "< 4.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_development_dependency(%q<fuubar>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<rspec-command>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<nokogiri>.freeze, [">= 1.5", "< 2.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<treetop>.freeze, ["~> 1.4"])
      s.add_dependency(%q<ffi-yajl>.freeze, ["~> 2.0"])
      s.add_dependency(%q<erubis>.freeze, [">= 0"])
      s.add_dependency(%q<rufus-lru>.freeze, ["~> 1.0"])
      s.add_dependency(%q<cucumber-core>.freeze, [">= 1.3", "< 4.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_dependency(%q<fuubar>.freeze, ["~> 2.0"])
      s.add_dependency(%q<rspec-command>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.5", "< 2.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<treetop>.freeze, ["~> 1.4"])
    s.add_dependency(%q<ffi-yajl>.freeze, ["~> 2.0"])
    s.add_dependency(%q<erubis>.freeze, [">= 0"])
    s.add_dependency(%q<rufus-lru>.freeze, ["~> 1.0"])
    s.add_dependency(%q<cucumber-core>.freeze, [">= 1.3", "< 4.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<fuubar>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rspec-command>.freeze, ["~> 1.0"])
  end
end
