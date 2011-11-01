module RubyAMI
  class Client
    def initialize(options)
      @options = options
      @state = :stopped
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start()
      @command_queue = Queue.new
      @response_queue = Queue.new
      EventMachine.run do
          @state = :started
          connection = Stream.start @options[:server], @options[:port], lambda {|response| @response_queue << response } #stuff with reference to queue
          loop do
            action = @command_queue.pop
            connection.send_command action
            #something

          end

          #Stream.start #stuff with reference to block to execute when stuff comes in from non-event stream
      end      
    end

    def send_message()
      @command_queue << Action.new(action_name, nil, headers)
      @response_queue.pop
    end

    #def message_received(message)
    #  p message
    #end

    def queue_worker()
    end

    
  end
end
