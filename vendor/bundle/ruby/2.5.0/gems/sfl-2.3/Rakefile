require "rspec/core/rake_task"

task :default => :spec

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end

desc "Create the .gem package"
require 'rubygems/package_task'
$gemspec = eval("#{File.read('sfl.gemspec')}")
Gem::PackageTask.new($gemspec) do |pkg|
  pkg.need_tar = true
end
