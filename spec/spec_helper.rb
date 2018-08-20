#require 'simplecov'
#SimpleCov.start

require 'bridge'
root = File.dirname(__FILE__)

Dir[File.join(root,'support', '**','*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"
end

include Bridge