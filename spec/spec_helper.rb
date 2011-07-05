require 'ruby_ami'
require 'mocha'

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
