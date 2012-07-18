require 'cgi'

module RubyAMI
  class AsyncAGIEnvironmentParser
    def initialize(environment_string)
      @environment_string = environment_string.dup
    end

    def to_hash
      to_array.inject({}) do |accumulator, element|
        accumulator[element[0].to_sym] = element[1] || ''
        accumulator
      end
    end

    def to_s
      @environment_string.dup
    end

    private

    def to_array
      CGI.unescape(@environment_string).split("\n").map { |p| p.split ': ' }
    end
  end
end
