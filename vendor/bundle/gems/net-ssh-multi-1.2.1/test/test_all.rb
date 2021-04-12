#     $ ruby -Ilib -Itest -rrubygems test/test_all.rb
#     $ ruby -Ilib -Itest -rrubygems test/channel_test.rb
Dir["#{File.dirname(__FILE__)}/**/*_test.rb"].each do |file|
  load(file)
end