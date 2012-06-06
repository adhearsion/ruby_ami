%w{
  uuidtools
  eventmachine
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
  client
  error
  event
  lexer
  metaprogramming
  response
  stream
  version
}.each { |f| require "ruby_ami/#{f}" }
