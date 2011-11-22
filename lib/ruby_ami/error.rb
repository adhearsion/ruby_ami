module RubyAMI
  class Error < StandardError
    attr_accessor :message, :action

    def initialize
      @headers = HashWithIndifferentAccess.new
    end

    def [](key)
      @headers[key]
    end

    def []=(key,value)
      @headers[key] = value
    end

    def action_id
      @headers['ActionID']
    end

    def inspect
      "#<#{self.class} #{[:message, :headers].map { |c| "#{c}=#{self.__send__(c).inspect rescue nil}" }.compact * ', '}>"
    end
  end
end # RubyAMI