%w{
  uuidtools
  future-resource
  logger
  girl_friday
  countdownlatch
  celluloid/io
}.each { |f| require f }

class Logger
  alias :trace :debug
end

module RubyAMI
end

%w{
  action
  agi_result_parser
  async_agi_environment_parser
  client
  error
  event
  lexer
  metaprogramming
  response
  stream
  version
}.each { |f| require "ruby_ami/#{f}" }
