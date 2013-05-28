# encoding: utf-8

module RubyAMI
  class Lexer
    TOKENS = {
      cr: /\r/, #UNUSED?
      lf: /\n/, #UNUSED?
      crlf: /\r\n/, #UNUSED?
      loose_newline: /\r?\n/, #UNUSED?
      white: /[\t ]/, #UNUSED?
      colon: /: */, #UNUSED?
      stanza_break: /\r\n\r\n/,
      rest_of_line: /(.*)?\r\n/, #UNUSED?
      prompt: /Asterisk Call Manager\/(\d+\.\d+)\r\n/,
      key: /([[[:alnum:]][[:print:]]])[\r\n:]+/, #UNUSED?
      keyvaluepair: /^([[[:alnum:]]-_ ]+): *(.*)\r\n/,
      followsdelimiter: /\r?\n?--END COMMAND--\r\n\r\n/,
      response: /response: */i, #UNUSED?
      success: /response: *success\r\n/i,
      pong: /response: *pong\r\n/i,
      event: /event: *(.*)?\r\n/i,
      error: /response: *error\r\n/i,
      follows: /response: *follows\r\n/i,
      followsbody: /(.*)?\r?\n?(?:--END COMMAND--\r\n\r\n|\r\n\r\n\r\n)/m
    }
    
    attr_accessor :ami_version

    def initialize(delegate = nil)
      @delegate = delegate
      @data = ""
      @ami_version = 0.0
    end

    def <<(new_data)
      extend_buffer_with new_data
      parse_buffer
    end

    def parse_buffer
      # Special case for the protocol header
      if @data =~ TOKENS[:prompt]
        @ami_version = $1
        @data.slice!(/.*\r\n/)
      end

      # We need at least one complete message before parsing
      return unless @data =~ TOKENS[:stanza_break]

      @processed = ''

      response_follows_message = false
      current_message = nil
      @data.scan(/.*?#{TOKENS[:stanza_break]}/m).each do |raw|
        if response_follows_message
          if handle_response_follows response_follows_message, raw
            @processed << raw
            message_received response_follows_message
            response_follows_message = nil
          end
        else
          response_follows_message = parse_message raw
        end
      end
      @data.slice! 0, @processed.length
      @processed = ''
    end

    def extend_buffer_with(new_data)
      @data << new_data
    end

    protected

    def parse_message(raw)
      msg = case raw
      when ''
        # Ignore blank lines
        @processed << raw
        return
      when TOKENS[:event]
        Event.new $1
      when TOKENS[:success], TOKENS[:pong]
        Response.new
      when TOKENS[:follows]
        response_follows = true
        Response.new
      when TOKENS[:error]
        Error.new
      end

      # Mark this message as processed, including the 4 stripped cr/lf bytes
      @processed << raw

      # Strip off the header line
      raw.slice!(/.*\r\n/)
      populate_message_body msg, raw

      if response_follows
        unless handle_response_follows(msg, raw)
          return msg
        end
      end

      if msg.class == Error
        error_received msg
      else
        message_received msg
      end
      nil
    end

    ##
    # Called after a response or event has been successfully parsed.
    #
    # @param [Response, Event] message The message just received
    #
    def message_received(message)
      @delegate.message_received message
    end

    ##
    # Called after an AMI error has been successfully parsed.
    #
    # @param [Response, Event] message The message just received
    #
    def error_received(message)
      @delegate.error_received message
    end

    ##
    # Called when there's a syntax error on the socket. This doesn't happen as often as it should because, in many cases,
    # it's impossible to distinguish between a syntax error and an immediate packet.
    #
    # @param [String] ignored_chunk The offending text which caused the syntax error.
    def syntax_error_encountered(ignored_chunk)
      @delegate.syntax_error_encountered ignored_chunk
    end

    def populate_message_body(obj, raw)
      while raw.slice! TOKENS[:keyvaluepair]
        obj[$1] = $2
      end
      obj
    end

    def handle_response_follows(obj, raw)
      obj.text_body ||= ''
      obj.text_body << raw
      if raw =~ TOKENS[:followsdelimiter]
        obj.text_body.sub! TOKENS[:followsdelimiter], ''
        obj.text_body.chomp!
        return true
      end
      false
    end
  end
end

