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

    def initialize(host, port, event_callback)
      super()
      @event_callback = event_callback
      logger.debug "Starting up..."
      @lexer = Lexer.new self
      @socket = TCPSocket.from_ruby_socket ::TCPSocket.new(host, port)
      post_init
      run!
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def run
      loop { receive_data @socket.readpartial(4096) }
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

    alias :error_received :message_received

    def finalize
      logger.debug "Finalizing stream"
      @socket.close if @socket
      @state = :stopped
      @event_callback.call Disconnected.new
    end

    def logger
      Logger
    end
  end
end
