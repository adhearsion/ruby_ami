require 'cgi'

module RubyAMI
  class AGIResultParser
    attr_reader :code, :result, :data

    FORMAT          = /^(\d{3}) result=(-?\d*) ?(\(?.*\)?)?$/.freeze
    DATA_KV_FORMAT  = /([\w\d]+)=([\w\d]*)/.freeze
    DATA_CLEANER    = /(^\()|(\)$)/.freeze

    def initialize(result_string)
      @result_string = result_string.dup
      raise ArgumentError, "The result string did not match the required format." unless match
      parse
    end

    def data_hash
      return unless data_kv_match
      {data_kv_match[1] => data_kv_match[2]}
    end

    private

    def unescape
      CGI.unescape @result_string
    end

    def match
      @match ||= unescape.chomp.match(FORMAT)
    end

    def parse
      @code = match[1].to_i
      @result = match[2].to_i
      @data = match[3] ? match[3].gsub(DATA_CLEANER, '').freeze : nil
    end

    def data_kv_match
      @data_kv_match ||= data.match(DATA_KV_FORMAT)
    end
  end
end
