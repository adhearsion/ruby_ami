module RubyAMI
  class Client
    def initialize(options)
      @queue = Queue.new
      @queue.extend(MonitorMixin)
      @empty_condition = @queue.new_cond
      EventMachine.run do
        Thread.start do
          connection = Stream.start options[:server].delete, options[:port].delete, options[:handler].delete, options #stuff with reference to queue
          loop do
            @empty_condition.wait_while {@queue.empty?}
            action = @queue.pop
            connection.send_command action
            #something

          end
        end

        Thread.start do
          Stream.start #stuff with reference to block to execute when stuff comes in from non-event stream
        end
      end      
    end

    def send_message()
      response_resource = FutureResource.new
      @queue << Action.new(action_name, headers, response_resource)
      respose_resource.resource
    end

    #def message_received(message)
    #  p message
    #end

    def queue_worker()
    end

    
  end
end
