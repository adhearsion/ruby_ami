# encoding: utf-8
require 'ruby_ami/response'

module RubyAMI
  class Event < Response
    attr_reader :name

    def initialize(name, headers = {})
      super headers
      @name = name
    end

    def inspect_attributes
      [:name] + super
    end
  end
end # RubyAMI
