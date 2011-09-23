require 'simplecov'
require 'simplecov-rcov'
class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.start do
  add_filter "/vendor/"
end

require 'ruby_ami'
require 'mocha'
require 'countdownlatch'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

include RubyAMI

RSpec.configure do |config|
  config.mock_with :mocha
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :each do
    UUIDTools::UUID.stubs :random_create => 'actionid'
  end
end
