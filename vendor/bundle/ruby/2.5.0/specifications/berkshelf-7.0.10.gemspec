# -*- encoding: utf-8 -*-
# stub: berkshelf 7.0.10 ruby lib

Gem::Specification.new do |s|
  s.name = "berkshelf".freeze
  s.version = "7.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamie Winsor".freeze, "Josiah Kiehl".freeze, "Michael Ivey".freeze, "Justin Campbell".freeze, "Seth Vargo".freeze]
  s.date = "2020-04-27"
  s.description = "Manages a Chef cookbook's dependencies".freeze
  s.email = ["jamie@vialstudios.com".freeze, "jkiehl@riotgames.com".freeze, "michael.ivey@riotgames.com".freeze, "justin@justincampbell.me".freeze, "sethvargo@gmail.com".freeze]
  s.executables = ["berks".freeze]
  s.files = ["bin/berks".freeze]
  s.homepage = "https://docs.chef.io/berkshelf.html".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "2.7.5".freeze
  s.summary = "Manages a Chef cookbook's dependencies".freeze

  s.installed_by_version = "2.7.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
      s.add_runtime_dependency(%q<cleanroom>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<minitar>.freeze, [">= 0.6"])
      s.add_runtime_dependency(%q<retryable>.freeze, ["< 4.0", ">= 2.0"])
      s.add_runtime_dependency(%q<solve>.freeze, ["~> 4.0"])
      s.add_runtime_dependency(%q<thor>.freeze, [">= 0.20"])
      s.add_runtime_dependency(%q<octokit>.freeze, ["~> 4.0"])
      s.add_runtime_dependency(%q<mixlib-archive>.freeze, ["< 2.0", ">= 0.4"])
      s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<chef>.freeze, [">= 13.6.52"])
      s.add_runtime_dependency(%q<chef-config>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<mixlib-config>.freeze, [">= 2.2.5"])
    else
      s.add_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
      s.add_dependency(%q<cleanroom>.freeze, ["~> 1.0"])
      s.add_dependency(%q<minitar>.freeze, [">= 0.6"])
      s.add_dependency(%q<retryable>.freeze, ["< 4.0", ">= 2.0"])
      s.add_dependency(%q<solve>.freeze, ["~> 4.0"])
      s.add_dependency(%q<thor>.freeze, [">= 0.20"])
      s.add_dependency(%q<octokit>.freeze, ["~> 4.0"])
      s.add_dependency(%q<mixlib-archive>.freeze, ["< 2.0", ">= 0.4"])
      s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
      s.add_dependency(%q<chef>.freeze, [">= 13.6.52"])
      s.add_dependency(%q<chef-config>.freeze, [">= 0"])
      s.add_dependency(%q<mixlib-config>.freeze, [">= 2.2.5"])
    end
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, ["< 4.0", ">= 2.0"])
    s.add_dependency(%q<cleanroom>.freeze, ["~> 1.0"])
    s.add_dependency(%q<minitar>.freeze, [">= 0.6"])
    s.add_dependency(%q<retryable>.freeze, ["< 4.0", ">= 2.0"])
    s.add_dependency(%q<solve>.freeze, ["~> 4.0"])
    s.add_dependency(%q<thor>.freeze, [">= 0.20"])
    s.add_dependency(%q<octokit>.freeze, ["~> 4.0"])
    s.add_dependency(%q<mixlib-archive>.freeze, ["< 2.0", ">= 0.4"])
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    s.add_dependency(%q<chef>.freeze, [">= 13.6.52"])
    s.add_dependency(%q<chef-config>.freeze, [">= 0"])
    s.add_dependency(%q<mixlib-config>.freeze, [">= 2.2.5"])
  end
end
