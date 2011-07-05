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

    def post_init
      send_action "Login", "Username" => @username, "Secret" => @password
    end

    def send_action(action_name, headers = {})
      action = Action.new action_name, headers
      send_data action.to_s
    end

    def receive_data(data)
      p "Stream receiving data: #{data}"
      @lexer << data
    end
  end
end
