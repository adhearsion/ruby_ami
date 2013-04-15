# encoding: utf-8
module RubyAMI
  class Client
    include Celluloid

    trap_exit :stream_died

    attr_reader :events_stream, :actions_stream

    def initialize(options)
      @options        = options
      @event_handler  = @options[:event_handler]
      @state          = :stopped
      client          = current_actor
      @events_stream  = new_stream ->(event) { client.async.handle_event event }
      @actions_stream = new_stream ->(message) { client.async.handle_message message }
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start
      @events_stream.async.run
      @actions_stream.async.run
      @state = :started
    end

    def send_action(*args)
      actions_stream.send_action *args
    end

    def handle_message(message)
      logger.trace "[RECV-ACTIONS]: #{message.inspect}"
      case message
      when Stream::Connected
        send_action 'Events', 'EventMask' => 'Off'
      when Stream::Disconnected
      when Event
        pass_event message
      end
    end

    def handle_event(event)
      logger.trace "[RECV-EVENTS]: #{event.inspect}"
      case event
      when Stream::Connected, Stream::Disconnected
      else
        pass_event event
      end
    end

    private

    def pass_event(event)
      @event_handler.call event if @event_handler.respond_to? :call
    end

    def new_stream(callback)
      Stream.new_link @options[:host], @options[:port], @options[:username], @options[:password], callback, logger, @options[:timeout]
    end

    def stream_died(stream, reason = nil)
      terminate
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
  end
end
