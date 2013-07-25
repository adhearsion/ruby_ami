# encoding: utf-8
require 'cgi'

module RubyAMI
  class AsyncAGIEnvironmentParser
    NEWLINE = '%0A'.freeze
    COLON_SPACE = '%3A%20'.freeze

    def initialize(environment_string)
      @environment_string = environment_string.dup
    end

    def to_hash
      hash= {}
      @environment_string.split(NEWLINE).map! do |p|
        p.split COLON_SPACE
      end.each do |element_0, element_1|
        hash[element_0.to_sym] = CGI.unescape(element_1 || '')
      end
      hash
    end

    def to_s
      @environment_string.dup
    end
  end
end
