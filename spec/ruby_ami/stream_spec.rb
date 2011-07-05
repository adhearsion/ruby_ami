require 'spec_helper'

module RubyAMI
  describe Stream do
    class MockServer; end
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

        # Mocked server
        EventMachine::start_server '127.0.0.1', 12345, ServerMock

        # Blather::Stream connection
        EM.connect('127.0.0.1', 12345, Stream, @client, 'username', 'pass') { |c| @stream = c }
      }
    end

    it 'can be started' do
      client = mock
      EM.expects(:connect).with do |*parms|
        parms[0].should == 'example.com'
        parms[1].should == 1234
        parms[2].should == Stream
        parms[3].should == client
        parms[4].should == 'username'
        parms[5].should == 'password'
      end

      Stream.start client, 'example.com', 1234, 'username', 'password'
    end

    describe "after connection" do
      it "logs in" do
        mocked_server(1) do |val, _|
          EM.stop
          val.should == Action.new('Login', 'Username' => 'username', 'Secret' => 'pass').to_s
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

    it 'puts itself in the stopped state and calls @client.unbind when unbound' do
      pending
      @client = mock()
      @client.expects(:unbind).at_least_once

      started = false
      mocked_server(2) do |val, server|
        if !started
          started = true
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.must_match(/stream:stream/)

        else
          EM.stop
          @stream.stopped?.must_equal false
          @stream.unbind
          @stream.stopped?.must_equal true

        end
      end
    end

    it 'stops when sent </stream:stream>' do
      pending
      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' xml:lang='en'>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.must_match(/stream:stream/)

        when :started
          state = :stopped
          server.send_data '</stream:stream>'
          @stream.stopped?.must_equal false

        when :stopped
          EM.stop
          @stream.stopped?.must_equal true
          val.must_equal '</stream:stream>'

        else
          EM.stop
          false

        end
      end
    end

    it 'sends client an error on stream:error' do
      pending
      @client = mock()
      @client.expects(:receive_data).with do |v|
        v.name.must_equal :conflict
        v.text.must_equal 'Already signed in'
        v.to_s.must_equal "Stream Error (conflict): #{v.text}"
      end

      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.must_match(/stream:stream/)

        when :started
          state = :stopped
          server.send_data "<stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams' />"
          server.send_data "<text xmlns='urn:ietf:params:xml:ns:xmpp-streams'>Already signed in</text></stream:error>"

        when :stopped
          EM.stop
          val.must_equal "</stream:stream>"

        else
          EM.stop
          false

        end
      end
    end
  end
end
