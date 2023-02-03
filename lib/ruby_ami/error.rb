# encoding: utf-8
module RubyAMI
  class Error < StandardError
    attr_accessor :message, :action, :text_body

    def initialize(headers = {})
      @headers = headers
    end

    def text_body
      if @text_body
        @text_body
      elsif output
        output
      else
        nil
      end
    end

    def has_text_body?
      !!text_body
    end

    def [](key)
      @headers[key]
    end

    def []=(key,value)
      self.message = value if key == 'Message'
      @headers[key] = value
    end

    def action_id
      @headers['ActionID']
    end

    def output
      @headers['Output']
    end

    def inspect
      "#<#{self.class} #{[:message, :headers].map { |c| "#{c}=#{self.__send__(c).inspect rescue nil}" }.compact * ', '}>"
    end
  end
end # RubyAMI
