# -*- encoding: utf-8 -*-
# stub: cleanroom 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "cleanroom".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Seth Vargo".freeze]
  s.date = "2014-08-12"
  s.description = "Ruby is an excellent programming language for creating and managing custom DSLs, but how can you securely evaluate a DSL while explicitly controlling the methods exposed to the user? Our good friends instance_eval and instance_exec are great, but they expose all methods - public, protected, and private - to the user. Even worse, they expose the ability to accidentally or intentionally alter the behavior of the system! The cleanroom pattern is a safer, more convenient, Ruby-like approach for limiting the information exposed by a DSL while giving users the ability to write awesome code!".freeze
  s.email = "sethvargo@gmail.com".freeze
  s.homepage = "https://github.com/sethvargo/cleanroom".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.7.5".freeze
  s.summary = "(More) safely evaluate Ruby DSLs with cleanroom".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
