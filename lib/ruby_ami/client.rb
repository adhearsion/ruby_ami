module RubyAMI
  class Client
    attr_reader :options, :action_queue, :events_stream, :actions_stream

    def initialize(options)
      @options          = options
      @logger           = options[:logger]
      @logger.level     = options[:log_level] || Logger::DEBUG if @logger
      @event_handler    = @options[:event_handler]
      @state            = :stopped

      stop_writing_actions

      @pending_actions  = {}
      @sent_actions     = {}
      @actions_lock     = Mutex.new

      @action_queue = GirlFriday::WorkQueue.new(:actions, :size => 1, :error_handler => ErrorHandler) do |action|
        @actions_write_blocker.wait
        _send_action action
        begin
          action.response action.sync_timeout
        rescue Timeout::Error => e
          logger.error "Timed out waiting for a response to #{action}"
        rescue RubyAMI::Error
          nil
        end
      end

      @message_processor = GirlFriday::WorkQueue.new(:messages, :size => 1, :error_handler => ErrorHandler) do |message|
        handle_message message
      end

      @event_processor = GirlFriday::WorkQueue.new(:events, :size => 2, :error_handler => ErrorHandler) do |event|
        handle_event event
      end
    end

    [:started, :stopped, :ready].each do |state|
      define_method("#{state}?") { @state == state }
    end

    def start
      @events_stream  = new_stream lambda { |event| @event_processor << event }
      @actions_stream = new_stream lambda { |message| @message_processor << message }
      streams.each(&:run!)
      @state = :started
      streams.each { |s| Celluloid::Actor.join s }
    end

    def stop
      streams.each do |stream|
        begin
          stream.terminate if stream.alive?
        rescue => e
          logger.error e if logger
        end
      end
    end

    def send_action(action, headers = {}, &block)
      (action.is_a?(Action) ? action : Action.new(action, headers, &block)).tap do |action|
        logger.trace "[QUEUE]: #{action.inspect}" if logger
        register_pending_action action
        action_queue << action
      end
    end

    def handle_message(message)
      logger.trace "[RECV-ACTIONS]: #{message.inspect}" if logger
      case message
      when Stream::Connected
        login_actions
      when Stream::Disconnected
        stop_writing_actions
        stop
      when Event
        action = @current_action_with_causal_events
        if action
          message.action = action
          action << message
          @current_action_with_causal_events = nil if action.complete?
        else
          if message.name == 'FullyBooted'
            pass_event message
            start_writing_actions
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
        @current_action_with_causal_events = action if action.has_causal_events?

        action << message
      end
    end

    def handle_event(event)
      logger.trace "[RECV-EVENTS]: #{event.inspect}" if logger
      case event
      when Stream::Connected
        login_events
      when Stream::Disconnected
        stop
      else
        pass_event event
      end
    end

    def _send_action(action)
      logger.trace "[SEND]: #{action.inspect}" if logger
      transition_action_to_sent action
      actions_stream.send_action action
      action.state = :sent
      action
    end

    private

    def pass_event(event)
      @event_handler.call event if @event_handler.respond_to? :call
    end

    def register_pending_action(action)
      @actions_lock.synchronize do
        @pending_actions[action.action_id] = action
      end
    end

    def transition_action_to_sent(action)
      @actions_lock.synchronize do
        @pending_actions.delete action.action_id
        @sent_actions[action.action_id] = action
      end
    end

    def sent_action_with_id(action_id)
      @actions_lock.synchronize do
        @sent_actions.delete action_id
      end
    end

    def start_writing_actions
      @actions_write_blocker.countdown!
    end

    def stop_writing_actions
      @actions_write_blocker = CountDownLatch.new 1
    end

    def login_actions
      action = login_action do |response|
        pass_event response if response.is_a? Error
        send_action 'Events', 'EventMask' => 'Off'
      end

      register_pending_action action
      Thread.new { _send_action action }
    end

    def login_events
      login_action.tap do |action|
        events_stream.send_action action
      end
    end

    def login_action(&block)
      Action.new 'Login',
                 'Username' => options[:username],
                 'Secret'   => options[:password],
                 'Events'   => 'On',
                 &block
    end

    def new_stream(callback)
      Stream.new @options[:host], @options[:port], callback, logger
    end

    def logger
      super
    rescue NoMethodError
      @logger
    end

    def streams
      [actions_stream, events_stream].compact
    end

    class ErrorHandler
      def handle(error)
        puts error.message
        puts error.backtrace.join("\n")
      end
    end
  end
end
