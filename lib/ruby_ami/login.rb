module RubyAMI
  class Login
    def self.connection(options)
      connection = Stream.start options[:server], options[:port], lambda {|response| options['Queue'] << response } #stuff with reference to queue
      action = Action.new('Login', 'Username' => options['Username'], 'Secret' => options['Secret'], 'Events' => options['Events'])
      connection.send_command action
      options['Queue'].pop
      connection 
    end
  end
end
