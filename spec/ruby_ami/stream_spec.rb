require 'spec_helper'

module RubyAMI
  describe Stream do
    MockServer = Class.new

    module ServerMock
      def receive_data(data)
        @server ||= MockServer.new
        @server.receive_data data, self
      end

      def send_data(data)
        super data.gsub("\n", "\r\n")
      end
    end

    def mocked_server(times = nil, &block)
      @client ||= mock()
      @client.stubs(:unbind) unless @client.respond_to?(:unbind)
      @client.stubs(:post_init) unless @client.respond_to?(:post_init)

      MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
      EventMachine::run {
        EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

        port = 50000 - rand(1000)

        # Mocked server
        EventMachine::start_server '127.0.0.1', port, ServerMock

        # Stream connection
        #EM.connect('127.0.0.1', port, Stream, @client, 'username', 'pass', @events) { |c| @stream = c }
        options = {:username => 'username', :password => 'pass', :events => @events}
        EM.connect('127.0.0.1', port, Stream, options) {|c| @stream = c}
      }
    end

    it 'can be started' do
      #client = mock
      EM.expects(:connect).with do |*parms|
        parms[0].should == 'example.com'
        parms[1].should == 1234
        parms[2].should == Stream
        parms[3].should == {:username => 'username', :password => 'password', :events => true}
#        parms[4].should == 'username'
#        parms[5].should == 'password'
#        parms[6].should == true
      end

      Stream.start 'example.com', 1234, {:username => 'username', :password => 'password', :events => true}
    end

    describe "after connection" do
      it "should be started" do
        mocked_server(1) do |val, server|
          @stream.started?.should be_true
        end
      end

      it "logs in" do
        @client = mock
        @client.expects(:on_stream_ready).with do |r|
          r.should be_a Stream
          r.should be_ready
        end
        mocked_server(1) do |val, server|
          val.should == Action.new('Login', 'Username' => 'username', 'Secret' => 'pass', 'Events' => 'On').to_s
          server.send_data <<-RESPONSE
Response: Success
ActionID: actionid
Message: Authentication accepted

          RESPONSE
        end
      end

      describe "with events turned off" do
        before { @events = false }

        it "logs in" do
          @client = mock
          @client.expects(:on_stream_ready).with do |r|
            r.should be_a Stream
            r.should be_ready
          end
          mocked_server(1) do |val, server|
            val.should == Action.new('Login', 'Username' => 'username', 'Secret' => 'pass', 'Events' => 'Off').to_s
            server.send_data <<-RESPONSE
Response: Success
ActionID: actionid
Message: Authentication accepted

            RESPONSE
          end
        end
      end
    end

    it 'sends events to the client when the stream is ready' do
      @client = mock
      @client.expects(:message_received).with do |e|
        EM.stop
        e.should be_a Event
        e.name.should == 'Hangup'
      end

      mocked_server(1) do |val, server|
        server.send_data <<-EVENT
Event: Hangup
Channel: SIP/101-3f3f
Uniqueid: 1094154427.10
Cause: 0

        EVENT
      end
    end

    it 'sends responses to the client when the stream is ready' do
      @client = mock
      @client.expects(:message_received).with do |r|
        EM.stop
        r.should be_a Response
        r['ActionID'].should == 'ee33eru2398fjj290'
      end

      mocked_server(1) do |val, server|
        server.send_data <<-EVENT
Response: Success
ActionID: ee33eru2398fjj290
Message: Authentication accepted

        EVENT
      end
    end

    it 'puts itself in the stopped state and calls @client.unbind when unbound' do
      @client = mock
      @client.expects(:unbind).at_least_once

      started = false
      mocked_server(1) do |val, server|
        EM.stop
        @stream.stopped?.should be false
        @stream.unbind
        @stream.stopped?.should be true
      end
    end
  end
end
