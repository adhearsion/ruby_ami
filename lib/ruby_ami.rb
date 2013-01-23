%w{
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
  def self.new_uuid
    SecureRandom.uuid
  end
  
  def self.rbx?
    RbConfig::CONFIG['RUBY_INSTALL_NAME'] == 'rbx'
  end
end

%w{
  core_ext/celluloid
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
