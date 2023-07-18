require "connection_pool"

module RubyAMI
  class PooledStream
    def initialize(options)
      self.options = options
    end

    def run
      self.reader_stream = RubyAMI::Stream.new(*option_stream_values)
      create_writer_pool
      reader_stream.run
    end

    def method_missing(method, *args, &block)
      writer_stream_pool.with do |stream|
        stream.__send__(method, *args, &block)
      end
    end

    private
    attr_accessor :options, :writer_stream_pool, :reader_stream

    def create_writer_pool
      self.writer_stream_pool = ConnectionPool.new(size: 10, timeout: 5) do
        stream = RubyAMI::Stream.new(*option_stream_values, 'Off')
        stream.async.run
        stream
      end
    end

    def option_stream_values
      options.values_at(
        :host, 
        :port, 
        :username, 
        :password, 
        :event_callback, 
        :logger, 
        :timeout
      )
    end
  end
end