require 'bundler'
Bundler.require(:default)

require 'pathname'

module Elio
  class << self
    attr_accessor :root
  end
  self.root = Pathname.new(File.expand_path("..", __FILE__))
end

$:.unshift(Elio.root) unless $:.include?(Elio.root)

require 'elio/version'
require 'elio/responders/github_responder'
