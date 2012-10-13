# encoding: utf-8
module RubyAMI
  class Stream
    class ConnectionStatus
      def eql?(other)
        other.is_a? self.class
      end

      alias :== :eql?
    end

    Connected = Class.new ConnectionStatus
    Disconnected = Class.new ConnectionStatus

    include Celluloid::IO

    attr_reader :logger

    def initialize(host, port, event_callback, logger = Logger)
      super()
      @host, @port, @event_callback, @logger = host, port, event_callback, logger
      logger.debug "Starting up..."
      @lexer = Lexer.new self
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def run
      @socket = TCPSocket.from_ruby_socket ::TCPSocket.new(@host, @port)
      post_init
      loop { receive_data @socket.readpartial(4096) }
    rescue Errno::ECONNREFUSED, SocketError => e
      logger.error "Connection failed due to #{e.class}. Check your config and the server."
      current_actor.terminate!
    rescue EOFError
      logger.info "Client socket closed!"
      current_actor.terminate!
    end

    def post_init
      @state = :started
      @event_callback.call Connected.new
    end

    def send_data(data)
      @socket.write data
    end

    def send_action(action)
      logger.debug "[SEND] #{action.to_s}"
      send_data action.to_s
    end

    def receive_data(data)
      logger.debug "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      logger.debug "[RECV] #{message.inspect}"
      @event_callback.call message
    end

    def syntax_error_encountered(ignored_chunk)
      logger.error "Encountered a syntax error. Ignoring chunk: #{ignored_chunk.inspect}"
    end

    alias :error_received :message_received

    def finalize
      logger.debug "Finalizing stream"
      @socket.close if @socket
      @state = :stopped
      @event_callback.call Disconnected.new
    end
  end
end
