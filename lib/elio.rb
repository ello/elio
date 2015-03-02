require 'bundler'
Bundler.require(:default)

require 'pathname'

module Elio
  class << self
    attr_accessor :root
  end
  self.root = Pathname.new(File.expand_path("..", __FILE__))
end

$:.unshift(Elio.root.to_s) unless $:.include?(Elio.root.to_s)

require 'elio/version'
require 'elio/responders/github_responder'

Bitbot.configure do |config|

  config.user_name = 'elio'
  config.full_name = 'Elio'

  config.webhook_url = ENV['BITBOT_INCOMING_WEBHOOK_URL']
  config.redis_connection = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')

  config.locales = Dir[Elio.root.join('config/locales/**/*.yml').to_s]
  config.responders = Dir[Elio.root.join('lib/elio/responders/**/*_responder.rb').to_s]

  config.listener :web do |listener|
    listener.token = ENV['BITBOT_OUTGOING_WEBHOOK_TOKEN'] || 'token'

    listener.port = 3000
    listener.path = '/rack-bitbot-webhook'
  end

  # this will preload the responders
  config.load_responders

end
