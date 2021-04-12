# -*- encoding: utf-8 -*-
# stub: ffi-libarchive 1.0.17 ruby lib

Gem::Specification.new do |s|
  s.name = "ffi-libarchive".freeze
  s.version = "1.0.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Bellone".freeze, "Jamie Winsor".freeze, "Frank Fischer".freeze]
  s.date = "2021-02-10"
  s.description = "A Ruby FFI binding to libarchive.".freeze
  s.email = ["jbellone@bloomberg.net".freeze, "jamie@vialstudios.com".freeze, "frank-fischer@shadow-soft.de".freeze]
  s.homepage = "https://github.com/chef/ffi-libarchive".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A Ruby FFI binding to libarchive.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    else
      s.add_dependency(%q<ffi>.freeze, ["~> 1.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<ffi>.freeze, ["~> 1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
  end
end
