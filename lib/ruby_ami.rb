%w{
  active_support/dependencies/autoload
}.each { |f| require f }

module RubyAMI
  extend ActiveSupport::Autoload

  autoload :Version
end
