require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'pathname'

root = Pathname.new(File.expand_path('../../lib', __FILE__))
$:.unshift(root.to_s) unless $:.include?(root.to_s)


Bitbot.configure do |config|

  config.user_name = 'elio'
  config.full_name = 'Elio'

  config.webhook_url = ENV['BITBOT_INCOMING_WEBHOOK_URL']
  config.redis_connection = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')

  config.locales = Dir[root.join('config/locales/**/*.yml').to_s]
  config.responders = Dir[root.join('lib/elio/responders/**/*_responder.rb')]

  config.listener :web do |listener|
    listener.token = ENV['BITBOT_OUTGOING_WEBHOOK_TOKEN'] || 'token'

    listener.port = 3000
    listener.path = '/rack-bitbot-webhook'
  end

  # this will preload the responders
  config.load_responders

end

run Bitbot.listener(:web)
