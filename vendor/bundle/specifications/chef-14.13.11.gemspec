# -*- encoding: utf-8 -*-
# stub: chef 14.13.11 ruby lib

Gem::Specification.new do |s|
  s.name = "chef".freeze
  s.version = "14.13.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Jacob".freeze]
  s.date = "2019-05-30"
  s.description = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.".freeze
  s.email = "adam@chef.io".freeze
  s.executables = ["chef-client".freeze, "chef-solo".freeze, "knife".freeze, "chef-shell".freeze, "chef-apply".freeze, "chef-resource-inspector".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze, "bin/chef-apply".freeze, "bin/chef-client".freeze, "bin/chef-resource-inspector".freeze, "bin/chef-shell".freeze, "bin/chef-solo".freeze, "bin/knife".freeze]
  s.homepage = "https://www.chef.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<chef-config>.freeze, ["= 14.13.11"])
      s.add_runtime_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
      s.add_runtime_dependency(%q<mixlib-log>.freeze, [">= 2.0.3", "< 4.0"])
      s.add_runtime_dependency(%q<mixlib-authentication>.freeze, ["~> 2.1"])
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 2.4", "< 4.0"])
      s.add_runtime_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
      s.add_runtime_dependency(%q<ohai>.freeze, ["~> 14.0"])
      s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.9", ">= 1.9.25"])
      s.add_runtime_dependency(%q<ffi-yajl>.freeze, ["~> 2.2"])
      s.add_runtime_dependency(%q<net-ssh>.freeze, ["~> 4.2"])
      s.add_runtime_dependency(%q<net-ssh-multi>.freeze, ["~> 1.2", ">= 1.2.1"])
      s.add_runtime_dependency(%q<net-sftp>.freeze, ["~> 2.1", ">= 2.1.2"])
      s.add_runtime_dependency(%q<highline>.freeze, ["~> 1.6", ">= 1.6.9"])
      s.add_runtime_dependency(%q<erubis>.freeze, ["~> 2.7"])
      s.add_runtime_dependency(%q<diff-lcs>.freeze, ["~> 1.2", ">= 1.2.4"])
      s.add_runtime_dependency(%q<chef-zero>.freeze, [">= 13.0"])
      s.add_runtime_dependency(%q<plist>.freeze, ["~> 3.2"])
      s.add_runtime_dependency(%q<iniparse>.freeze, ["~> 1.4"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rspec-core>.freeze, ["~> 3.5"])
      s.add_runtime_dependency(%q<rspec-expectations>.freeze, ["~> 3.5"])
      s.add_runtime_dependency(%q<rspec-mocks>.freeze, ["~> 3.5"])
      s.add_runtime_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.2.0"])
      s.add_runtime_dependency(%q<serverspec>.freeze, ["~> 2.7"])
      s.add_runtime_dependency(%q<specinfra>.freeze, ["~> 2.10"])
      s.add_runtime_dependency(%q<syslog-logger>.freeze, ["~> 1.6"])
      s.add_runtime_dependency(%q<uuidtools>.freeze, ["~> 2.1.5"])
      s.add_runtime_dependency(%q<proxifier>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<bundler>.freeze, [">= 1.10"])
    else
      s.add_dependency(%q<chef-config>.freeze, ["= 14.13.11"])
      s.add_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
      s.add_dependency(%q<mixlib-log>.freeze, [">= 2.0.3", "< 4.0"])
      s.add_dependency(%q<mixlib-authentication>.freeze, ["~> 2.1"])
      s.add_dependency(%q<mixlib-shellout>.freeze, [">= 2.4", "< 4.0"])
      s.add_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
      s.add_dependency(%q<ohai>.freeze, ["~> 14.0"])
      s.add_dependency(%q<ffi>.freeze, ["~> 1.9", ">= 1.9.25"])
      s.add_dependency(%q<ffi-yajl>.freeze, ["~> 2.2"])
      s.add_dependency(%q<net-ssh>.freeze, ["~> 4.2"])
      s.add_dependency(%q<net-ssh-multi>.freeze, ["~> 1.2", ">= 1.2.1"])
      s.add_dependency(%q<net-sftp>.freeze, ["~> 2.1", ">= 2.1.2"])
      s.add_dependency(%q<highline>.freeze, ["~> 1.6", ">= 1.6.9"])
      s.add_dependency(%q<erubis>.freeze, ["~> 2.7"])
      s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.2", ">= 1.2.4"])
      s.add_dependency(%q<chef-zero>.freeze, [">= 13.0"])
      s.add_dependency(%q<plist>.freeze, ["~> 3.2"])
      s.add_dependency(%q<iniparse>.freeze, ["~> 1.4"])
      s.add_dependency(%q<addressable>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-core>.freeze, ["~> 3.5"])
      s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.5"])
      s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.5"])
      s.add_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.2.0"])
      s.add_dependency(%q<serverspec>.freeze, ["~> 2.7"])
      s.add_dependency(%q<specinfra>.freeze, ["~> 2.10"])
      s.add_dependency(%q<syslog-logger>.freeze, ["~> 1.6"])
      s.add_dependency(%q<uuidtools>.freeze, ["~> 2.1.5"])
      s.add_dependency(%q<proxifier>.freeze, ["~> 1.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.10"])
    end
  else
    s.add_dependency(%q<chef-config>.freeze, ["= 14.13.11"])
    s.add_dependency(%q<mixlib-cli>.freeze, [">= 1.7", "< 3.0"])
    s.add_dependency(%q<mixlib-log>.freeze, [">= 2.0.3", "< 4.0"])
    s.add_dependency(%q<mixlib-authentication>.freeze, ["~> 2.1"])
    s.add_dependency(%q<mixlib-shellout>.freeze, [">= 2.4", "< 4.0"])
    s.add_dependency(%q<mixlib-archive>.freeze, [">= 0.4", "< 2.0"])
    s.add_dependency(%q<ohai>.freeze, ["~> 14.0"])
    s.add_dependency(%q<ffi>.freeze, ["~> 1.9", ">= 1.9.25"])
    s.add_dependency(%q<ffi-yajl>.freeze, ["~> 2.2"])
    s.add_dependency(%q<net-ssh>.freeze, ["~> 4.2"])
    s.add_dependency(%q<net-ssh-multi>.freeze, ["~> 1.2", ">= 1.2.1"])
    s.add_dependency(%q<net-sftp>.freeze, ["~> 2.1", ">= 2.1.2"])
    s.add_dependency(%q<highline>.freeze, ["~> 1.6", ">= 1.6.9"])
    s.add_dependency(%q<erubis>.freeze, ["~> 2.7"])
    s.add_dependency(%q<diff-lcs>.freeze, ["~> 1.2", ">= 1.2.4"])
    s.add_dependency(%q<chef-zero>.freeze, [">= 13.0"])
    s.add_dependency(%q<plist>.freeze, ["~> 3.2"])
    s.add_dependency(%q<iniparse>.freeze, ["~> 1.4"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-core>.freeze, ["~> 3.5"])
    s.add_dependency(%q<rspec-expectations>.freeze, ["~> 3.5"])
    s.add_dependency(%q<rspec-mocks>.freeze, ["~> 3.5"])
    s.add_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.2.0"])
    s.add_dependency(%q<serverspec>.freeze, ["~> 2.7"])
    s.add_dependency(%q<specinfra>.freeze, ["~> 2.10"])
    s.add_dependency(%q<syslog-logger>.freeze, ["~> 1.6"])
    s.add_dependency(%q<uuidtools>.freeze, ["~> 2.1.5"])
    s.add_dependency(%q<proxifier>.freeze, ["~> 1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.10"])
  end
end
