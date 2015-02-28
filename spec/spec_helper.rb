require 'elio'

require 'pry'
require 'rspec'
require 'webmock/rspec'
require 'vcr'

Bitbot.configure do |config|
  config.redis_connection = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end
