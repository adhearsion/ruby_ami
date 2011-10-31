module RubyAMI
  class Stream < EventMachine::Connection
    def self.start(host, port, options)
      EM.connect host, port, self, options
    end

    attr_reader :login_action

    def initialize(options)
      super()
      @client, @username, @password, @events = options[:client], options[:username], options[:password], options[:events].nil? ? true : options[:events]
      @logger = options[:logger] || Logger.new($stdout)
      #@logger.level = Logger::FATAL
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
      @login_action = Action.new 'Login', nil, "Username" => @username, "Secret" => @password, 'Events' => @events ? 'On' : 'Off'
      send_data @login_action.to_s
    end

    def send_action(action)
#      Action.new(action_name, headers, &block).tap do |action|
      @logger.debug "[SEND] #{action.to_s}"
      @action = action
      send_data action.to_s
#      end
    end

    def receive_data(data)
      @logger.debug "[RECV] #{data}"
      @lexer << data
    end

    def message_received(message)
      @logger.debug "[RECV] #{message.inspect}"
      p "message is is #{message.action_id} and action is #{@action.action_id if @action}"
      if message.action_id == @login_action.action_id
        @logger.debug "Login response received: #{message.inspect}"
        @state = :ready
      elsif message.action_id == @action.action_id
        p 'got to setting'
        @action.response_resource.resource = @action.response 
        #@client.message_received message
      end
    end

    # Called by EM when the connection is closed
    # @private
    def unbind
      @state = :stopped
    end
  end
end
