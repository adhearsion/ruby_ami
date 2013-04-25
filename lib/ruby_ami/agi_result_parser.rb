require 'cgi'

module RubyAMI
  class AGIResultParser
    attr_reader :code, :result, :data

    FORMAT          = /^(?<code>\d{3})( result=(?<result>-?\d*))? ?(?<data>\(?.*\)?)?$/.freeze
    DATA_KV_FORMAT  = /(?<key>[\w\d]+)=(?<value>[\w\d]*)/.freeze
    DATA_CLEANER    = /(^\()|(\)$)/.freeze

    def initialize(result_string)
      @result_string = result_string.dup
      raise ArgumentError, "The result string did not match the required format." unless match
      parse
    end

    def data_hash
      return unless data_kv_match
      {data_kv_match[:key] => data_kv_match[:value]}
    end

    private

    def unescape
      CGI.unescape @result_string
    end

    def match
      @match ||= unescape.chomp.match(FORMAT)
    end

    def parse
      @code = match[:code].to_i
      @result = match[:result] ? match[:result].to_i : nil
      @data = match[:data] ? match[:data].gsub(DATA_CLEANER, '').freeze : nil
    end

    def data_kv_match
      @data_kv_match ||= data.match(DATA_KV_FORMAT)
    end
  end
end
