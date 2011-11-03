module RubyAMI
  class Client
    attr_reader :options, :action_queue, :events_stream, :actions_stream

    def initialize(options)
      @options          = options
      @state            = :stopped
      @pending_actions  = {}

      @actions_write_blocker = CountDownLatch.new 1

      @action_queue = GirlFriday::WorkQueue.new(:actions, :size => 1, :error_handler => ErrorHandler) do |action|
        @actions_write_blocker.wait
        _send_action action
      end

      @message_processor = GirlFriday::WorkQueue.new(:messages, :size => 2, :error_handler => ErrorHandler) do |message|
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
        yield
        @events_stream  = start_stream lambda { |event| @event_processor << event }
        @actions_stream = start_stream lambda { |message| @message_processor << message }
        @state = :started
      end
    end

    def send_action(action, headers = {}, &block)
      (action.is_a?(Action) ? action : Action.new(action, headers, &block)).tap do |action|
        @pending_actions[action.action_id] = action
        action_queue << action
      end
    end

    def handle_message(message)
      case message
      when Stream::Connected
        start_writing_actions
        login_actions
      when Response
        @pending_actions.delete(message.action_id).response = message
      end
    end

    def handle_event(event)
      login_events if event.is_a? Stream::Connected
    end

    private

    def _send_action(action)
      actions_stream.send_action action
      action.state = :sent
      action.response
      action.state = :complete
    end

    def start_writing_actions
      @actions_write_blocker.countdown!
    end

    def login_actions
      @action_queue << login_action
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
