# -*- encoding: utf-8 -*-
# stub: chef-cli 2.0.10 ruby lib

Gem::Specification.new do |s|
  s.name = "chef-cli".freeze
  s.version = "2.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chef Software, Inc.".freeze]
  s.date = "2020-05-05"
  s.description = "A streamlined development and deployment workflow for Chef platform.".freeze
  s.email = ["info@chef.io".freeze]
  s.executables = ["chef-cli".freeze]
  s.files = ["bin/chef-cli".freeze]
  s.homepage = "https://www.chef.io/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A streamlined development and deployment workflow for Chef platform.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 2.0", "< 4.0"])
      s.add_runtime_dependency(%q<ffi-yajl>.freeze, [">= 1.0", "< 3.0"])
      s.add_runtime_dependency(%q<minitar>.freeze, ["~> 0.6"])
      s.add_runtime_dependency(%q<chef>.freeze, [">= 14.0"])
      s.add_runtime_dependency(%q<solve>.freeze, ["> 2.0", "< 5.0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.3.5", "< 2.8"])
      s.add_runtime_dependency(%q<cookbook-omnifetch>.freeze, ["~> 0.5"])
      s.add_runtime_dependency(%q<diff-lcs>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<paint>.freeze, [">= 1", "< 3"])
      s.add_runtime_dependency(%q<license-acceptance>.freeze, ["~> 1.0", ">= 1.0.11"])
    else
      s.add_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
      s.add_dependency(%q<mixlib-shellout>.freeze, [">= 2.0", "< 4.0"])
      s.add_dependency(%q<ffi-yajl>.freeze, [">= 1.0", "< 3.0"])
      s.add_dependency(%q<minitar>.freeze, ["~> 0.6"])
      s.add_dependency(%q<chef>.freeze, [">= 14.0"])
      s.add_dependency(%q<solve>.freeze, ["> 2.0", "< 5.0"])
      s.add_dependency(%q<addressable>.freeze, [">= 2.3.5", "< 2.8"])
      s.add_dependency(%q<cookbook-omnifetch>.freeze, ["~> 0.5"])
      s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.0"])
      s.add_dependency(%q<paint>.freeze, [">= 1", "< 3"])
      s.add_dependency(%q<license-acceptance>.freeze, ["~> 1.0", ">= 1.0.11"])
    end
  else
    s.add_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
    s.add_dependency(%q<mixlib-shellout>.freeze, [">= 2.0", "< 4.0"])
    s.add_dependency(%q<ffi-yajl>.freeze, [">= 1.0", "< 3.0"])
    s.add_dependency(%q<minitar>.freeze, ["~> 0.6"])
    s.add_dependency(%q<chef>.freeze, [">= 14.0"])
    s.add_dependency(%q<solve>.freeze, ["> 2.0", "< 5.0"])
    s.add_dependency(%q<addressable>.freeze, [">= 2.3.5", "< 2.8"])
    s.add_dependency(%q<cookbook-omnifetch>.freeze, ["~> 0.5"])
    s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.0"])
    s.add_dependency(%q<paint>.freeze, [">= 1", "< 3"])
    s.add_dependency(%q<license-acceptance>.freeze, ["~> 1.0", ">= 1.0.11"])
  end
end
