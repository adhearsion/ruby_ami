module RubyAMI
  class Client
    def initialize(options)
      @queue = Queue.new
      EventMachine.run do
          connection = Stream.start options[:server].delete, options[:port].delete, options[:handler].delete, options #stuff with reference to queue
          loop do
            action = @queue.pop
            connection.send_command action.to_s
            #something

          end

          Stream.start #stuff with reference to block to execute when stuff comes in from non-event stream
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
