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
      @sent_actions   = {}
      @causal_actions = {}
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
    rescue EOFError
      logger.info "Client socket closed!"
    rescue Timeout::Error
      logger.error "Timeout exceeded while trying to connect."
    ensure
      async.terminate
    end

    def post_init
      @state = :started
      fire_event Connected.new
    end

    def send_data(data)
      @socket.write data
    end

    def send_action(name, headers = {})
      action = Action.new name, headers
      logger.trace "[SEND] #{action.to_s}"
      register_sent_action action
      send_data action.to_s
      wait action.action_id
      action.response.tap do |resp|
        abort resp if resp.is_a? Exception
      end
    end

    def login(username, password, event_mask = 'On')
      send_action 'Login',
        'Username' => username,
        'Secret'   => password,
        'Events'   => event_mask
    end

    def receive_data(data)
      logger.trace "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      logger.trace "[RECV] #{message.inspect}"
      case message
      when Event
        action = causal_action_for_event message
        if action
          action << message
          complete_causal_action_for_event message if action.complete?
        else
          fire_event message
        end
      when Response, Error
        action = sent_action_for_response message
        raise StandardError, "Received an AMI response with an unrecognized ActionID! #{message.inspect}" unless action
        action << message
      end
    end

    def syntax_error_encountered(ignored_chunk)
      logger.error "Encountered a syntax error. Ignoring chunk: #{ignored_chunk.inspect}"
    end

    alias :error_received :message_received

    private

    def fire_event(event)
      @event_callback.call event
    end

    def register_sent_action(action)
      @sent_actions[action.action_id] = action
      register_causal_action action if action.has_causal_events?
    end

    def sent_action_with_id(action_id)
      @sent_actions.delete action_id
    end

    def sent_action_for_response(response)
      sent_action_with_id response.action_id
    end

    def register_causal_action(action)
      @causal_actions[action.action_id] = action
    end

    def causal_action_for_event(event)
      @causal_actions[event.action_id]
    end

    def complete_causal_action_for_event(event)
      @causal_actions.delete event.action_id
    end

    def finalize
      logger.debug "Finalizing stream"
      @socket.close if @socket
      @state = :stopped
      fire_event Disconnected.new
    end
  end
end
