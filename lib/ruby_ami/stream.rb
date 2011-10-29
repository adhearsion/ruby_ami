module RubyAMI
  class Stream < EventMachine::Connection
#    def self.start(client, host, port, username, pass, events, logger = nil)
#      EM.connect host, port, self, client, username, pass, events, logger
    def self.start(host, port, options)
      EM.connect host, port, self, options
    end

    attr_reader :login_action

#    def initialize(client, username, password, events = true, logger = nil)
    def initialize(options)
      super()
      @client, @username, @password, @events = options[:client], options[:username], options[:password], options[:events].nil? ? true : options[:events]
      @logger = options[:logger] || Logger.new($stdout)
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
      @login_action = send_action "Login", "Username" => @username, "Secret" => @password, 'Events' => @events ? 'On' : 'Off' do |action|
        @logger.debug "Handling login response..."
        @state = :ready
        @client.on_stream_ready self
      end
    end

    def send_action(action)
#      Action.new(action_name, headers, &block).tap do |action|
#        @logger.debug "[SEND] #{action.to_s}"
#        send_data action.to_s
#      end
    end

    def receive_data(data)
      @logger.debug "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      @logger.debug "[RECV] #{message.inspect}"
      if message.action_id == @login_action.action_id
        @logger.debug "Login response received: #{message.inspect}"
        @login_action.response = message
      else
        #@client.message_received message
      end
    end

    # Called by EM when the connection is closed
    # @private
    def unbind
      @state = :stopped
      #@client.unbind
    end
  end
end
