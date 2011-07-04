%w{
  active_support/dependencies/autoload
  active_support/core_ext/object/blank
  active_support/core_ext/numeric/time
  active_support/core_ext/numeric/bytes
  active_support/hash_with_indifferent_access
}.each { |f| require f }

module RubyAMI
  extend ActiveSupport::Autoload

  autoload :Lexer
  autoload :Version
end
