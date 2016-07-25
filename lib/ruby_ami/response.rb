# encoding: utf-8
module RubyAMI
  ##
  # This is the object containing a response from Asterisk.
  #
  class Response
    class << self
      def from_immediate_response(text)
        new.tap do |instance|
          instance.text_body = text
        end
      end
    end

    attr_accessor :text_body, # For "Response: Follows" sections
                  :events

    def initialize(headers = {})
      @headers = headers
      @events = []
    end

    def has_text_body?
      !!@text_body
    end

    def headers
      @headers.clone
    end

    def merge_headers!(hash)
      @headers.merge!(hash)
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

    def inspect
      "#<#{self.class} #{inspect_attributes.map { |c| "#{c}=#{self.__send__(c).inspect rescue nil}" }.compact * ', '}>"
    end

    def inspect_attributes
      [:headers, :text_body, :events]
    end

    def eql?(o, *fields)
      o.is_a?(self.class) && (fields + inspect_attributes).all? { |f| self.__send__(f) == o.__send__(f) }
    end
    alias :== :eql?
  end
end # RubyAMI
