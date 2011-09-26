module RubyAMI
  class Stream < EventMachine::Connection
    def self.start(client, host, port, username, pass, logger = nil)
      EM.connect host, port, self, client, username, pass, logger
    end

    attr_reader :login_action

    def initialize(client, username, password, logger = nil)
      super()
      @client, @username, @password = client, username, password
      @logger = logger || Logger.new($stdout)
      @logger.level = Logger::DEBUG
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
      @login_action = send_action("Login", "Username" => @username, "Secret" => @password)
    end

    def send_action(action_name, headers = {}, &block)
      Action.new(action_name, headers, &block).tap do |action|
        @logger.debug "[SEND] #{action.to_s}"
        send_data action.to_s
      end
    end

    def receive_data(data)
      @logger.debug "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      @logger.debug "[RECV] #{message.inspect}"
      @client.message_received message
    end

    # Called by EM when the connection is closed
    # @private
    def unbind
      @state = :stopped
      @client.unbind
    end
  end
end
