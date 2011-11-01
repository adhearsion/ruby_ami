module RubyAMI
  class Client
    attr_reader :options, :action_queue

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
        @events_stream = Stream.start @options[:server],
                                      @options[:port],
                                      lambda { |event| handle_event event }

        #Stream.start #stuff with reference to block to execute when stuff comes in from non-event stream

        @state = :started
      end      
    end

    def send_action(action_name, headers, &block)
      @action_queue << Action.new(action_name, headers, &block)
    end

    def message_received(message)
    end

    def handle_event(event)
    end
  end
end
