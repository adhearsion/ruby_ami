class IntrospectiveManagerStreamLexer < RubyAMI::Lexer
  attr_reader :received_messages, :syntax_errors, :ami_errors

  def initialize(*args)
    super
    @received_messages = []
    @syntax_errors     = []
    @ami_errors        = []
  end

  def message_received(message = @current_message)
    @received_messages << message
  end

  def error_received(error_message)
    @ami_errors << error_message
  end

  def syntax_error_encountered(ignored_chunk)
    @syntax_errors << ignored_chunk
  end
end
