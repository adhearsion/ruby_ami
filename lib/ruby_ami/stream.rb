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
      @login_action = send_action("Login", "Username" => @username, "Secret" => @password) { |response| p "BOO"; @client.login_callback.call if @client.login_callback }
      # @state = :ready
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
      action_id = message["ActionID"]
      corresponding_action = data_for_message_received_with_action_id action_id
      if corresponding_action
        message.action = corresponding_action

        if corresponding_action.has_causal_events?
          # By this point the write loop will already have started blocking by calling the response() method on the
          # action. Because we must collect more events before we wake the write loop up again, let's create these
          # instance variable which will needed when the subsequent causal events come in.
          @current_action_with_causal_events   = corresponding_action
          @event_collection_for_current_action = []
        else
          # Wake any Threads waiting on the response.
          corresponding_action.future_resource.resource = message
        end
      else
        # ahn_log.ami.error "Received an AMI message with an unrecognized ActionID!! This may be an bug! #{message.inspect}"
      end
      @client.message_received message
    end

    ##
    # When we send out an AMI action, we need to track the ActionID and have the other Thread handling the socket IO
    # notify the sending Thread that a response has been received. This method instantiates a new FutureResource and
    # keeps it around in a synchronized Hash for the IO-handling Thread to notify when a response with a matching
    # ActionID is seen again. See also data_for_message_received_with_action_id() which is how the IO-handling Thread
    # gets the metadata registered in the method back later.
    #
    # @param [ManagerInterfaceAction] action The ManagerInterfaceAction to send
    # @param [Hash] headers The other key/value pairs being sent with this message
    #
    def register_action_with_metadata(action)
      raise ArgumentError, "Must supply an action!" if action.nil?
      @sent_messages_lock.synchronize do
        @sent_messages[action.action_id] = action
      end
    end

    def data_for_message_received_with_action_id(action_id)
      @sent_messages_lock.synchronize do
        @sent_messages.delete action_id
      end
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
