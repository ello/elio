require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'pathname'

root = Pathname.new(File.expand_path('../../lib', __FILE__))
$:.unshift(root.to_s) unless $:.include?(root.to_s)

run Bitbot.listener(:web)
