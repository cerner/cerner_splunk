
Gem::Specification.new do |s|

  s.name = 'rufus-lru'

  s.version = File.read(
    File.expand_path('../lib/rufus/lru.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://github.com/jmettraux/rufus-lru'
  s.rubyforge_project = 'rufus'
  s.license = 'MIT'
  s.summary = 'A Hash with a max size, controlled by a LRU mechanism'

  s.description = %{
LruHash class, a Hash with a max size, controlled by a LRU mechanism
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  #s.add_runtime_dependency 'tzinfo', '>= 0.3.23'

  s.add_development_dependency 'rspec', '>= 3.4.0'

  s.require_path = 'lib'
end

