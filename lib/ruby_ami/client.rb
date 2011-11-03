module RubyAMI
  class Client
    attr_reader :options, :action_queue, :events_stream, :actions_stream

    def initialize(options)
      @options          = options
      @event_handler    = @options[:event_handler]
      @state            = :stopped

      @actions_write_blocker = CountDownLatch.new 1

      @pending_actions  = {}
      @sent_actions     = {}
      @actions_lock     = Mutex.new

      @action_queue = GirlFriday::WorkQueue.new(:actions, :size => 1, :error_handler => ErrorHandler) do |action|
        @actions_write_blocker.wait
        _send_action action
        action.response
      end

      @message_processor = GirlFriday::WorkQueue.new(:messages, :size => 1, :error_handler => ErrorHandler) do |message|
        handle_message message
      end

      @event_processor = GirlFriday::WorkQueue.new(:events, :size => 2, :error_handler => ErrorHandler) do |event|
        handle_event event
      end
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start
      EventMachine.run do
        yield if block_given?
        @events_stream  = start_stream lambda { |event| @event_processor << event }
        @actions_stream = start_stream lambda { |message| @message_processor << message }
        @state = :started
      end
    end

    def send_action(action, headers = {}, &block)
      (action.is_a?(Action) ? action : Action.new(action, headers, &block)).tap do |action|
        register_pending_action action
        action_queue << action
      end
    end

    def handle_message(message)
      case message
      when Stream::Connected
        start_writing_actions
        login_actions
      when Event
        action = @current_action_with_causal_events
        raise StandardError, "Got an unexpected event on actions socket! This AMI command may have a multi-message response. Try making Adhearsion treat it as causal action #{message.inspect}" unless action
        message.action = action
        action << message
        @current_action_with_causal_events = nil if action.complete?
      when Response
        action = sent_action_with_id message.action_id
        raise StandardError, "Received an AMI response with an unrecognized ActionID!! This may be an bug! #{message.inspect}" unless action
        message.action = action

        # By this point the write loop will already have started blocking by calling the response() method on the
        # action. Because we must collect more events before we wake the write loop up again, let's create these
        # instance variable which will needed when the subsequent causal events come in.
        @current_action_with_causal_events = action if action.has_causal_events?

        action << message
      end
    end

    def handle_event(event)
      @event_handler.call event if @event_handler.respond_to? :call
      login_events if event.is_a? Stream::Connected
    end

    def _send_action(action)
      transition_action_to_sent action
      actions_stream.send_action action
      action.state = :sent
    end

    private

    def register_pending_action(action)
      @actions_lock.synchronize do
        @pending_actions[action.action_id] = action
      end
    end

    def transition_action_to_sent(action)
      @actions_lock.synchronize do
        @pending_actions.delete action.action_id
        @sent_actions[action.action_id] = action
      end
    end

    def sent_action_with_id(action_id)
      @actions_lock.synchronize do
        @sent_actions.delete action_id
      end
    end

    def start_writing_actions
      @actions_write_blocker.countdown!
    end

    def login_actions
      send_action login_action
    end

    def login_events
      login_action('On').tap do |action|
        events_stream.send_action action
      end
    end

    def login_action(events = 'Off')
      Action.new 'Login',
                 'Username' => options[:username],
                 'Secret' => options[:password],
                 'Events' => events
    end

    def start_stream(callback)
      Stream.start @options[:server], @options[:port], callback
    end

    class ErrorHandler
      def handle(error)
        puts error
        puts error.backtrace.join("\n")
      end
    end
  end
end
