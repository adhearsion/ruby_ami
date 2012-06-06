require 'spec_helper'

module RubyAMI
  describe Stream do
    let(:server_port) { 50000 - rand(1000) }

    def mocked_server(times = nil, fake_client = nil, &block)
      MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
      s = ServerMock.new '127.0.0.1', server_port
      EventMachine::run {
        EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

        # Stream connection
        EM.connect('127.0.0.1', server_port, Stream, lambda { |m| client.message_received m }) {|c| @stream = c}

        fake_client.call if fake_client.respond_to? :call
      }
      s.terminate
    end

    def expect_connected_event
      client.expects(:message_received).with Stream::Connected.new
    end

    def expect_disconnected_event
      client.expects(:message_received).with Stream::Disconnected.new
    end

    before { @sequence = 1 }

    it 'can be started' do
      EM.expects(:connect).with do |*params|
        params[0].should == 'example.com'
        params[1].should == 1234
        params[2].should == Stream
        params[3].should be_a Proc
      end

      Stream.start 'example.com', 1234, lambda {}
    end

    describe "after connection" do
      it "should be started" do
        expect_connected_event
        expect_disconnected_event
        mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
          @stream.started?.should be_true
        end
      end

      it "can send a command" do
        expect_connected_event
        expect_disconnected_event
        action = Action.new('Command', 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On')
        mocked_server(1, lambda { @stream.send_action action }) do |val, server|
          val.should == action.to_s
        end
      end
    end

    it 'sends events to the client when the stream is ready' do
      client.expects(:message_received).times(3).with do |e|
        case @sequence
        when 1
          e.should be_a Stream::Connected
        when 2
          EM.stop
          e.should be_a Event
          e.name.should == 'Hangup'
          e['Channel'].should == 'SIP/101-3f3f'
          e['Uniqueid'].should == '1094154427.10'
          e['Cause'].should == '0'
        when 3
          e.should be_a Stream::Disconnected
        end
        @sequence += 1
      end

      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        server.send_data <<-EVENT
Event: Hangup
Channel: SIP/101-3f3f
Uniqueid: 1094154427.10
Cause: 0

        EVENT
      end
    end

    it 'sends responses to the client when the stream is ready' do
      client.expects(:message_received).times(3).with do |r|
        case @sequence
        when 1
          r.should be_a Stream::Connected
        when 2
          EM.stop
          r.should be_a Response
          r['ActionID'].should == 'ee33eru2398fjj290'
          r['Message'].should == 'Authentication accepted'
        when 3
          r.should be_a Stream::Disconnected
        end
        @sequence += 1
      end

      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        server.send_data <<-EVENT
Response: Success
ActionID: ee33eru2398fjj290
Message: Authentication accepted

        EVENT
      end
    end

    it 'sends error to the client when the stream is ready and a bad command was send' do
      client.expects(:message_received).times(3).with do |r|
        case @sequence
        when 1
          r.should be_a Stream::Connected
        when 2
          EM.stop
          r.should be_a Error
          r['ActionID'].should == 'ee33eru2398fjj290'
          r['Message'].should == 'You stupid git'
        when 3
          r.should be_a Stream::Disconnected
        end
        @sequence += 1
      end

      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        server.send_data <<-EVENT
Response: Error
ActionID: ee33eru2398fjj290
Message: You stupid git

        EVENT
      end
    end

    it 'puts itself in the stopped state and fires a disconnected event when unbound' do
      expect_connected_event
      expect_disconnected_event
      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        EM.stop
        @stream.stopped?.should be false
      end
      @stream.stopped?.should be true
    end
  end
end
