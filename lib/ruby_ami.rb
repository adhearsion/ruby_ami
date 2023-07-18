%w{
  celluloid/io
}.each { |f| require f }

class Logger
  alias :trace :debug
end

module RubyAMI
  def self.new_uuid
    SecureRandom.uuid
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
  response
  stream
  pooled_stream
  version
}.each { |f| require "ruby_ami/#{f}" }
