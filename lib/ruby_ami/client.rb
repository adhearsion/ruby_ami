module RubyAMI
  class Client
    attr_reader :options, :action_queue, :events_stream, :actions_stream

    def initialize(options)
      @options      = options
      @state        = :stopped
      @action_queue = GirlFriday::WorkQueue.new(:actions, :size => 1) do |action|
        _send_action action
      end

      @message_processor = GirlFriday::WorkQueue.new(:messages, :size => 2) do |message|
        handle_message message
      end

      @event_processor = GirlFriday::WorkQueue.new(:events, :size => 2) do |event|
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

    def send_action(action_name, headers, &block)
      action_queue << Action.new(action_name, headers, &block)
    end

    def handle_message(message)
      login_actions if message.is_a? Stream::Connected
    end

    def handle_event(event)
      login_events if event.is_a? Stream::Connected
    end

    private

    def _send_action(action)
      actions_stream.send_action action
    end

    def login_actions
      login_action.tap do |action|
        actions_stream.send_action action
      end
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
  end
end
