module RubyAMI
  class Stream < EventMachine::Connection
    Connected = Class.new

    def self.start(host, port, event_callback)
      EM.connect host, port, self, event_callback
    end

    def initialize(event_callback)
      super()
      @event_callback = event_callback
      @logger = Logger.new($stdout)
      @logger.level = Logger::FATAL
      @logger.debug "Starting up..."
      @lexer = Lexer.new self
      @sent_messages_lock = Mutex.new
      @sent_messages = {}
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def post_init
      @state = :started
      @event_callback.call Connected.new
    end

    def send_action(action)
      @logger.debug "[SEND] #{action.to_s}"
      @action = action
      send_data action.to_s
    end

    def receive_data(data)
      @logger.debug "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      @logger.debug "[RECV] #{message.inspect}"
      @event_callback.call message
    end
    
    alias :error_received :message_received

    # Called by EM when the connection is closed
    # @private
    def unbind
      @state = :stopped
    end
  end
end
