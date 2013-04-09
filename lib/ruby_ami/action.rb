module RubyAMI
  class Action
    attr_reader :name, :headers, :action_id, :response

    CAUSAL_EVENT_NAMES = %w[queuestatus sippeers iaxpeers parkedcalls dahdishowchannels coreshowchannels
                            dbget status agents konferencelist confbridgelist confbridgelistrooms] unless defined? CAUSAL_EVENT_NAMES

    def initialize(name, headers = {})
      @name       = name.to_s.downcase.freeze
      @headers    = headers.freeze
      @action_id  = RubyAMI.new_uuid
      @response   = nil
      @complete   = false
      @events     = []
    end

    def complete?
      @complete
    end

    ##
    # When sending an action with "causal events" (i.e. events which must be collected to form a proper
    # response), AMI should send a particular event which instructs us that no more events will be sent.
    # This event is called the "causal event terminator".
    #
    # Note: you must supply both the name of the event and any headers because it's possible that some uses of an
    # action (i.e. same name, different headers) have causal events while other uses don't.
    #
    # @param [String] name the name of the event
    # @param [Hash] the headers associated with this event
    # @return [String] the downcase()'d name of the event name for which to wait
    #
    def has_causal_events?
      CAUSAL_EVENT_NAMES.include? name
    end

    ##
    # Used to determine the event name for an action which has causal events.
    #
    # @param [String] action_name
    # @return [String] The corresponding event name which signals the completion of the causal event sequence.
    #
    def causal_event_terminator_name
      return unless has_causal_events?
      case name
      when "sippeers", "iaxpeers"
        "peerlistcomplete"
      when "konferencelist"
        "conferencelistcomplete"
      else
        name + "complete"
      end
    end

    ##
    # Converts this action into a protocol-valid String, ready to be sent over a socket.
    #
    def to_s
      @textual_representation ||= (
          "Action: #{@name}\r\nActionID: #{@action_id}\r\n" +
          @headers.map { |(key,value)| "#{key}: #{value}" }.join("\r\n") +
          (@headers.any? ? "\r\n\r\n" : "\r\n")
      )
    end

    def <<(message)
      case message
      when Error
        self.response = message
        complete!
      when Event
        raise StandardError, 'This action should not trigger events. Maybe it is now a causal action? This is most likely a bug in RubyAMI' unless has_causal_events?
        response.events << message
        complete! if message.name.downcase == causal_event_terminator_name
      when Response
        self.response = message
        complete! unless has_causal_events?
      end
      self
    end

    def eql?(other)
      to_s == other.to_s
    end
    alias :== :eql?

    private

    def response=(other)
      @response = other
    end

    def complete!
      @complete = true
    end
  end
end # RubyAMI
