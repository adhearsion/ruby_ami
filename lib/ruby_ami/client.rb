# encoding: utf-8
module RubyAMI
  class Client
    include Celluloid

    attr_reader :events_stream, :actions_stream

    def initialize(options)
      @options          = options
      @event_handler    = @options[:event_handler]
      @state            = :stopped
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
        actions_stream.send_action action
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
        pass_event message
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

    def login_actions
      action = login_action do |response|
        send_action 'Events', 'EventMask' => 'Off'
      end

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
