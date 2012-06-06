module RubyAMI
  ##
  # This is the object containing a response from Asterisk.
  #
  # Note: not all responses have an ActionID!
  #
  class Response
    class << self
      def from_immediate_response(text)
        new.tap do |instance|
          instance.text_body = text
        end
      end
    end

    attr_accessor :action,
                  :text_body  # For "Response: Follows" sections
    attr_reader   :events

    def initialize
      @headers = Hash.new
    end

    def has_text_body?
      !!@text_body
    end

    def headers
      @headers.clone
    end

    def [](arg)
      @headers[arg.to_s]
    end

    def []=(key,value)
      @headers[key.to_s] = value
    end

    def action_id
      @headers['ActionID']
    end
  end
end # RubyAMI
