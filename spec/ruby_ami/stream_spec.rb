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

    def mocked_server(times = nil, fake_client = nil, &block)
      @client ||= mock
      
      MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
       EventMachine::run {
         EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

         port = 50000 - rand(1000)

         # Mocked server
         EventMachine::start_server '127.0.0.1', port, ServerMock

         # Stream connection
         EM.connect('127.0.0.1', port, Stream, lambda { |m| @client.message_received m }) {|c| @stream = c}

         fake_client.call if fake_client.respond_to? :call
       }
    end

    it 'can be started' do
      EM.expects(:connect).with do |*params|
        params[0].should == 'example.com'
        params[1].should == 1234
        params[2].should == Stream
        params[3].should be_a Proc
      end

      Stream.start('example.com', 1234, lambda {})
    end

    describe "after connection" do
      it "should be started" do
        mocked_server(0) do |val, server|
          @stream.started?.should be_true
        end
      end

      it "can send a command" do
        action = Action.new('Command', 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On') 
        mocked_server(1, lambda { @stream.send_action action }) do |val, server|
          val.should == action.to_s
        end
      end
    end

    it 'sends events to the client when the stream is ready' do
      @client = mock
      @client.expects(:message_received).with do |e|
        EM.stop
        e.should be_a Event
        e.name.should == 'Hangup'
        e['Channel'].should == 'SIP/101-3f3f'
        e['Uniqueid'].should == '1094154427.10'
        e['Cause'].should == '0'
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
      @client = mock
      @client.expects(:message_received).with do |r|
        EM.stop
        r.should be_a Response
        r['ActionID'].should == 'ee33eru2398fjj290'
        r['Message'].should == 'Authentication accepted'
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
      @client = mock
      @client.expects(:message_received).with do |r|
        EM.stop
        r.should be_a Error
        r['ActionID'].should == 'ee33eru2398fjj290'
        r['Message'].should == 'You stupid git'
      end

      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        server.send_data <<-EVENT
Response: Error
ActionID: ee33eru2398fjj290
Message: You stupid git

        EVENT
      end
    end

    it 'puts itself in the stopped state and calls @client.unbind when unbound' do
      started = false
      mocked_server(0) do |val, server|
        EM.stop
        @stream.stopped?.should be false
        @stream.unbind
        @stream.stopped?.should be true
      end
    end
  end
end
