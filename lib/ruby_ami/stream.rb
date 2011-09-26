module RubyAMI
  class Stream < EventMachine::Connection
    def self.start(client, host, port, username, pass)
      EM.connect host, port, self, client, username, pass
    end

    attr_reader :login_action

    def initialize(client, username, password)
      super()
      @client, @username, @password = client, username, password
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
        send_data action.to_s
      end
    end

    def receive_data(data)
      @lexer << data
    end

    def message_received(message)
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
