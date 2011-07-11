module RubyAMI
  class Stream < EventMachine::Connection
    def self.start(client, host, port, username, pass)
      EM.connect host, port, self, client, username, pass
    end

    def initialize(delegate, username, password)
      super()
      @delegate, @username, @password = delegate, username, password
      @lexer = Lexer.new self
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def post_init
      @state = :started
      send_action "Login", "Username" => @username, "Secret" => @password
    end

    def send_action(action_name, headers = {})
      action = Action.new action_name, headers
      send_data action.to_s
    end

    def receive_data(data)
      @lexer << data
    end

    def message_received(m)
      @delegate.message_received m
    end

    # Called by EM when the connection is closed
    # @private
    def unbind
      @state = :stopped
      @client.unbind
    end

    private

    def ready!
      @state = :ready
      # @client.post_init self
    end
  end
end
