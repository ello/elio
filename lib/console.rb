require 'bundler'
Bundler.require(:default, :development)

require_relative "./elio"

Bitbot.configure do |config|
  config.redis_connection = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')
end

Pry.config.prompt_name = "elio"

def octokit_client
  @client ||= Octokit::Client.new(access_token: ENV['ELIO_GITHUB_OAUTH_TOKEN'])
end

def redis
  @redis ||= Redis.new
end

def elio(message)
  @router ||= Bitbot::Router.new
  @router.route_message(Bitbot::Message.new(text: message, user_name: 'archer'))
end
