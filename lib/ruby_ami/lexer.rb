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
      keyvaluepair: /^([[:alnum:]]+): *(.*)\r\n/,
      followsdelimiter: /\r?\n--END COMMAND--/,
      response: /response: */i, #UNUSED?
      success: /response: *success\r\n/i,
      pong: /response: *pong\r\n/i,
      event: /event: *(.*)?\r\n/i,
      error: /response: *error\r\n/i,
      follows: /response: *follows\r\n/i,
      followsbody: /(.*)?\r?\n--END COMMAND--/
    }
    
    attr_accessor :ami_version

    def initialize(delegate = nil)
      @delegate = delegate
      @data = ""
      @current_pointer = 0
      @ami_version = 0.0

	    @current_pointer ||= 0
	    @data_ending_pointer ||=   @data.length
	    @token_start = nil
	    @token_end = nil
    end

    def <<(new_data)
      extend_buffer_with new_data
      parse_buffer
    end

    def parse_buffer
      return unless @data =~ TOKENS[:stanza_break]

      processed = ''

      @data.scan(/(.*?)#{TOKENS[:stanza_break]}/m).each do |raw|
        raw = raw.first
        response_follows = false
        msg = case raw
        when TOKENS[:prompt]
          @ami_version = $1
          processed << raw
          next
        when TOKENS[:event]
          Event.new $1
        when TOKENS[:success]
          Response.new
        when TOKENS[:error]
          Error.new
        when TOKENS[:pong]
          Pong.new
        when TOKENS[:follows]
          response_follows = true
          Response.new
        end

        # Mark this message as processed
        processed << raw

        # Strip off the header line
        raw.slice!(/.*\r\n/)
        # Terminate the last line of the message since the newline was lost with the stanza break
        raw << "\r\n"
        populate_message_body msg, raw

        handle_response_follows(msg, raw) if response_follows

        message_received msg
      end
      @data.slice! 0, processed.length + 4 # remove 4 extra bytes of \r\n\r\n
    end

    def extend_buffer_with(new_data)
      @data << new_data
      @data_ending_pointer = @data.size
    end

    protected

    ##
    # Called after a response or event has been successfully parsed.
    #
    # @param [Response, Event] message The message just received
    #
    def message_received(message)
      @delegate.message_received message
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
      puts "RAW: #{raw.inspect}"
      if raw =~ TOKENS[:followsbody]
        obj.text_body = $1.chomp
      end
    end
  end
end

