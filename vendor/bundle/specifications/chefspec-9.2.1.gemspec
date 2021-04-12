# -*- encoding: utf-8 -*-
# stub: chefspec 9.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "chefspec".freeze
  s.version = "9.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Crump".freeze, "Seth Vargo".freeze]
  s.date = "2020-08-14"
  s.description = "ChefSpec is a unit testing and resource coverage (code coverage) framework for testing Chef cookbooks ChefSpec makes it easy to write examples and get fast feedback on cookbook changes without the need for virtual machines or cloud servers.".freeze
  s.email = ["andrew.crump@ieee.org".freeze, "sethvargo@gmail.com".freeze]
  s.homepage = "https://github.com/chefspec/chefspec".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Write RSpec examples and generate coverage reports for Chef recipes!".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<chef>.freeze, [">= 14"])
      s.add_runtime_dependency(%q<chef-cli>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<fauxhai-ng>.freeze, [">= 7.5"])
      s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<chef>.freeze, [">= 14"])
      s.add_dependency(%q<chef-cli>.freeze, [">= 0"])
      s.add_dependency(%q<fauxhai-ng>.freeze, [">= 7.5"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<chef>.freeze, [">= 14"])
    s.add_dependency(%q<chef-cli>.freeze, [">= 0"])
    s.add_dependency(%q<fauxhai-ng>.freeze, [">= 7.5"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
