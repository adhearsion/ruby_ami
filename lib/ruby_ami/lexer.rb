# encoding: utf-8

module RubyAMI
  class Lexer
    STANZA_BREAK      = "\r\n\r\n"
    PROMPT            = /Asterisk Call Manager\/(\d+\.\d+)\r\n/
    KEYVALUEPAIR      = /^([[[:alnum:]]-_ ]+): *(.*)\r\n/
    FOLLOWSDELIMITER  = /\r?\n?--END COMMAND--\r\n\r\n/
    SUCCESS           = /response: *success/i
    PONG              = /response: *pong/i
    EVENT             = /event: *(?<event_name>.*)?/i
    ERROR             = /response: *error/i
    FOLLOWS           = /response: *follows/i
    GOODBYE           = /response: *goodbye/i
    SCANNER           = /.*?#{STANZA_BREAK}/m
    HEADER_SLICE      = /.*\r\n/
    IMMEDIATE_RESP    = /.*/
    CLASSIFIER        = /((?<event>#{EVENT})|(?<success>#{SUCCESS})|(?<pong>#{PONG})|(?<follows>#{FOLLOWS})|(?<error>#{ERROR})|(?<goodbye>#{GOODBYE})|(?<immediate>#{IMMEDIATE_RESP})\r\n)\r\n/i

    attr_accessor :ami_version

    def initialize(delegate = nil)
      @delegate = delegate
      @buffer = ""
      @ami_version = nil
    end

    def <<(new_data)
      @buffer << new_data
      parse_buffer
    end

    private

    def parse_buffer
      # Special case for the protocol header
      if @buffer =~ PROMPT
        @ami_version = $1
        @buffer.slice! HEADER_SLICE
      end

      # We need at least one complete message before parsing
      return unless @buffer.include?(STANZA_BREAK)

      @processed = 0

      response_follows_message = false
      current_message = nil
      @buffer.scan(SCANNER).each do |raw|
        if response_follows_message
          if handle_response_follows(response_follows_message, raw)
            @processed += raw.length
            message_received response_follows_message
            response_follows_message = nil
          end
        else
          response_follows_message = parse_message raw
        end
      end
      @buffer.slice! 0, @processed
    end

    def parse_message(raw)
      return if raw.length == 0

      # Mark this message as processed, including the 4 stripped cr/lf bytes
      @processed += raw.length

      match = raw.match CLASSIFIER

      msg = if match[:event]
        Event.new match[:event_name]
      elsif match[:success] || match[:pong] || match[:goodbye]
        Response.new
      elsif match[:follows]
        response_follows = true
        Response.new
      elsif match[:error]
        Error.new
      elsif match[:immediate]
        if raw.include?(':')
          syntax_error_encountered raw.chomp(STANZA_BREAK)
          return
        end
        immediate_response = true
        Response.from_immediate_response match[:immediate]
      end

      # Strip off the header line
      raw.slice! HEADER_SLICE
      populate_message_body msg, raw

      return msg if response_follows && !handle_response_follows(msg, raw)

      case msg
      when Error
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
      while raw.slice! KEYVALUEPAIR
        obj[$1] = $2
      end
      obj
    end

    def handle_response_follows(obj, raw)
      obj.text_body ||= ''
      obj.text_body << raw
      return false unless raw =~ FOLLOWSDELIMITER
      obj.text_body.sub! FOLLOWSDELIMITER, ''
      obj.text_body.chomp!
      true
    end
  end
end

