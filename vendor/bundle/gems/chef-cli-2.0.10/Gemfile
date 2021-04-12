source "https://rubygems.org"

gemspec

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :test do
  # For ruby 2.4 testing we need to use ohai 14
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.5")
    gem "ohai", "~> 14"
  end
  gem "rake"
  gem "rspec", "~> 3.8"
  gem "rspec-expectations", "~> 3.8"
  gem "rspec-mocks", "~> 3.8"
  gem "cookstyle"
  gem "chefstyle"
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
