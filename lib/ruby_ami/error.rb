module RubyAMI
  class Error < StandardError
    attr_accessor :message

    def initialize
      @headers = HashWithIndifferentAccess.new
    end

    def [](key)
      @headers[key]
    end

    def []=(key,value)
      @headers[key] = value
    end
  end
end # RubyAMI