# -*- encoding: utf-8 -*-
# stub: cookbook-omnifetch 0.11.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cookbook-omnifetch".freeze
  s.version = "0.11.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamie Winsor".freeze, "Josiah Kiehl".freeze, "Michael Ivey".freeze, "Justin Campbell".freeze, "Seth Vargo".freeze, "Daniel DeLeo".freeze]
  s.date = "2020-08-31"
  s.email = ["jamie@vialstudios.com".freeze, "jkiehl@riotgames.com".freeze, "michael.ivey@riotgames.com".freeze, "justin@justincampbell.me".freeze, "sethvargo@gmail.com".freeze, "dan@chef.io".freeze]
  s.homepage = "https://github.com/chef/cookbook-omnifetch".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Library code to fetch Chef cookbooks from a variety of sources to a local cache".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
    else
      s.add_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
    end
  else
    s.add_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
  end
end
