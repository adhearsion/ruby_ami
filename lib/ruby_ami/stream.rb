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

    finalizer :finalize

    def initialize(host, port, event_callback, logger = Logger, timeout = 0)
      super()
      @host, @port, @event_callback, @logger, @timeout = host, port, event_callback, logger, timeout
      logger.debug "Starting up..."
      @lexer = Lexer.new self
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def run
      Timeout::timeout(@timeout) do
        @socket = TCPSocket.from_ruby_socket ::TCPSocket.new(@host, @port)
      end
      post_init
      loop { receive_data @socket.readpartial(4096) }
    rescue Errno::ECONNREFUSED, SocketError => e
      logger.error "Connection failed due to #{e.class}. Check your config and the server."
      terminate
    rescue EOFError
      logger.info "Client socket closed!"
      terminate
    rescue Timeout::Error
      logger.error "Timeout exceeded while trying to connect."
      terminate
    end

    def post_init
      @state = :started
      @event_callback.call Connected.new
    end

    def send_data(data)
      @socket.write data
    end

    def send_action(action)
      logger.trace "[SEND] #{action.to_s}"
      send_data action.to_s
    end

    def receive_data(data)
      logger.trace "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      logger.trace "[RECV] #{message.inspect}"
      @event_callback.call message
    end

    def syntax_error_encountered(ignored_chunk)
      logger.error "Encountered a syntax error. Ignoring chunk: #{ignored_chunk.inspect}"
    end

    alias :error_received :message_received

    private

    def finalize
      logger.debug "Finalizing stream"
      @socket.close if @socket
      @state = :stopped
      @event_callback.call Disconnected.new
    end
  end
end
