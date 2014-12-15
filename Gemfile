require 'socket'

# rubocop:disable RescueModifier
internal = !Socket.gethostbyname('repo.release.cerner.corp').nil? rescue false
# rubocop:enable RescueModifier

source 'https://rubygems.org'
source 'http://repo.release.cerner.corp/internal/rubygems/' if internal

gem 'berkshelf', '~> 3.0', group: :deployment
gem 'rubocop', '~> 0.18'
gem 'foodcritic', '~> 4.0'

group :development do
  gem 'roll_out', '~> 1.6.0'
  gem 'rdoc', '~> 4.1.0'
  gem 'roll_out-jira'
end if internal
