# encoding: utf-8
require 'cgi'

module RubyAMI
  class AsyncAGIEnvironmentParser
    NEWLINE = "%0A".freeze
    COLON_SPACE = '%3A%20'.freeze

    def initialize(environment_string)
      @environment_string = environment_string.dup
    end

    def to_hash
      to_array.inject({}) do |accumulator, element|
        accumulator[element[0].to_sym] = CGI.unescape(element[1] || '')
        accumulator
      end
    end

    def to_s
      @environment_string.dup
    end

    private

    def to_array
      @environment_string.split(NEWLINE).map { |p| p.split COLON_SPACE }
    end
  end
end
