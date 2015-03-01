require 'elio'

require 'pry'
require 'rspec'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :none }
end
