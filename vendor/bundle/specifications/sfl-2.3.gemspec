# -*- encoding: utf-8 -*-
# stub: sfl 2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "sfl".freeze
  s.version = "2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["ujihisa".freeze, "blambeau".freeze]
  s.date = "2016-10-03"
  s.description = "Spawn For Ruby 1.8".freeze
  s.email = "ujihisa at gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/ujihisa/spawn-for-legacy".freeze
  s.licenses = ["Ruby".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Spawn For Ruby 1.8".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 2.4.0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 2.4.0"])
  end
end
