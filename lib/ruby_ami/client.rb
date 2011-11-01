module RubyAMI
  class Client
    attr_reader :options, :action_queue, :events_stream, :actions_stream

    def initialize(options)
      @options      = options
      @state        = :stopped
      @action_queue = Queue.new
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start
      EventMachine.run do
        @events_stream = start_stream lambda { |event| handle_event event }
        @actions_stream = start_stream lambda { |message| handle_message message }
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
