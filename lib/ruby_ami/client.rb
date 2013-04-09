# encoding: utf-8
module RubyAMI
  class Client
    include Celluloid

    attr_reader :events_stream, :actions_stream

    def initialize(options)
      @options          = options
      @event_handler    = @options[:event_handler]
      @state            = :stopped
      @sent_actions     = {}
      @causal_actions   = {}
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start
      @events_stream  = new_stream lambda { |event| handle_event event }
      @actions_stream = new_stream lambda { |message| handle_message message }
      streams.each { |stream| stream.async.run }
      @state = :started
    end

    def send_action(action, headers = {}, &block)
      (action.is_a?(Action) ? action : Action.new(action, headers, &block)).tap do |action|
        logger.trace "[SEND]: #{action.inspect}"
        register_sent_action action
        actions_stream.send_action action
        action.state = :sent
      end
    end

    def handle_message(message)
      logger.trace "[RECV-ACTIONS]: #{message.inspect}"
      case message
      when Stream::Connected
        login_actions
      when Stream::Disconnected
        terminate
      when Event
        action = @causal_actions[message.action_id]
        if action
          message.action = action
          action << message
          @causal_actions.delete(action.action_id) if action.complete?
        else
          if message.name == 'FullyBooted'
            pass_event message
          else
            raise StandardError, "Got an unexpected event on actions socket! This AMI command may have a multi-message response. Try making Adhearsion treat it as causal action #{message.inspect}"
          end
        end
      when Response, Error
        action = sent_action_with_id message.action_id
        raise StandardError, "Received an AMI response with an unrecognized ActionID!! This may be an bug! #{message.inspect}" unless action
        message.action = action

        # By this point the write loop will already have started blocking by calling the response() method on the
        # action. Because we must collect more events before we wake the write loop up again, let's create these
        # instance variable which will needed when the subsequent causal events come in.
        @causal_actions[action.action_id] = action if action.has_causal_events?

        action << message
      end
    end

    def handle_event(event)
      logger.trace "[RECV-EVENTS]: #{event.inspect}"
      case event
      when Stream::Connected
        login_events
      when Stream::Disconnected
        terminate
      else
        pass_event event
      end
    end

    private

    def pass_event(event)
      @event_handler.call event if @event_handler.respond_to? :call
    end

    def register_sent_action(action)
      @sent_actions[action.action_id] = action
    end

    def sent_action_with_id(action_id)
      @sent_actions.delete action_id
    end

    def login_actions
      action = login_action do |response|
        pass_event response if response.is_a? Error
        send_action 'Events', 'EventMask' => 'Off'
      end

      register_sent_action action
      send_action action
    end

    def login_events
      login_action.tap do |action|
        events_stream.send_action action
      end
    end

    def login_action(&block)
      Action.new 'Login',
                 'Username' => @options[:username],
                 'Secret'   => @options[:password],
                 'Events'   => 'On',
                 &block
    end

    def new_stream(callback)
      Stream.new_link @options[:host], @options[:port], callback, logger, @options[:timeout]
    end

    def logger
      super
    rescue
      @logger ||= begin
        logger = Logger
        logger.define_singleton_method :trace, logger.method(:debug)
        logger
      end
    end

    def streams
      [actions_stream, events_stream].compact
    end
  end
end
