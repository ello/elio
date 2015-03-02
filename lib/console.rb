require 'bundler'
Bundler.require(:default, :development)

require_relative "./elio"

Bitbot.configure do |config|
  config.redis_connection = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')
end

Pry.config.prompt_name = "elio"
