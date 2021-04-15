# -*- encoding: utf-8 -*-
# stub: paint 2.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "paint".freeze
  s.version = "2.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jan Lelis".freeze]
  s.date = "2020-12-09"
  s.description = "Terminal painter with RGB and 256 (fallback) color and terminal effects support. No string extensions! Usage: Paint['string', :red, :bright]".freeze
  s.email = ["hi@ruby.consulting".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze, "MIT-LICENSE.txt".freeze]
  s.files = ["CHANGELOG.md".freeze, "MIT-LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/janlelis/paint".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.7.5".freeze
  s.summary = "Terminal painter!".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
      s.add_development_dependency(%q<benchmark-ips>.freeze, ["~> 2.7"])
      s.add_development_dependency(%q<rainbow>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<term-ansicolor>.freeze, ["~> 1.7"])
      s.add_development_dependency(%q<ansi>.freeze, ["~> 1.5"])
      s.add_development_dependency(%q<hansi>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<pastel>.freeze, ["~> 0.7"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
      s.add_dependency(%q<benchmark-ips>.freeze, ["~> 2.7"])
      s.add_dependency(%q<rainbow>.freeze, ["~> 3.0"])
      s.add_dependency(%q<term-ansicolor>.freeze, ["~> 1.7"])
      s.add_dependency(%q<ansi>.freeze, ["~> 1.5"])
      s.add_dependency(%q<hansi>.freeze, ["~> 0.2"])
      s.add_dependency(%q<pastel>.freeze, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_dependency(%q<benchmark-ips>.freeze, ["~> 2.7"])
    s.add_dependency(%q<rainbow>.freeze, ["~> 3.0"])
    s.add_dependency(%q<term-ansicolor>.freeze, ["~> 1.7"])
    s.add_dependency(%q<ansi>.freeze, ["~> 1.5"])
    s.add_dependency(%q<hansi>.freeze, ["~> 0.2"])
    s.add_dependency(%q<pastel>.freeze, ["~> 0.7"])
  end
end
