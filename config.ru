require 'bundler'
Bundler.require(:default)

require_relative "lib/elio"

run Bitbot.listener(:web)
