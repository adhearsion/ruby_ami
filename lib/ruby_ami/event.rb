# encoding: utf-8
require 'ruby_ami/response'

module RubyAMI
  class Event < Response
    attr_reader :name, :receipt_time

    def initialize(name, headers = {})
      @receipt_time = DateTime.now
      super headers
      @name = name
    end

    # @return [DateTime, nil] the timestamp of the event, or nil if none is available
    def timestamp
      return unless headers['Timestamp']
      DateTime.strptime headers['Timestamp'], '%s'
    end

    # @return [DateTime] the best known timestamp for the event. Either its timestamp if specified, or its receipt time if not.
    def best_time
      timestamp || receipt_time
    end

    def inspect_attributes
      [:name] + super
    end
  end
end # RubyAMI
