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

    def mocked_server(times = nil, events, &block)
      thread = Thread.start do
        if times == 1
          MockServer.any_instance.expects(:receive_data).twice.with &block
        else
        MockServer.any_instance.expects(:receive_data).once.with() { |val, server|         
          val.should == Action.new('Login', nil, 'Username' => 'username', 'Secret' => 'pass', 'Events' => events).to_s
          server.send_data <<-RESPONSE
Response: Success
ActionID: actionid
Message: Authentication accepted

          RESPONSE
        }
        end
        #MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
        EventMachine::run {
          EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

          port = 50000 - rand(1000)

          # Mocked server
          EventMachine::start_server '127.0.0.1', port, ServerMock

          # Stream connection
          options = {:username => 'username', :password => 'pass', :events => @events}
          @connection = EM.connect('127.0.0.1', port, Stream, options) {|c| @stream = c}
        }
      end
      sleep 0.1
      thread
    end

    it 'can be started' do
      EM.expects(:connect).with do |*parms|
        parms[0].should == 'example.com'
        parms[1].should == 1234
        parms[2].should == Stream
        parms[3].should == {:username => 'username', :password => 'password', :events => true}
      end

      Stream.start 'example.com', 1234, {:username => 'username', :password => 'password', :events => true}
    end

    describe "after connection" do
      it "should be started" do
        (mocked_server(0, 'On') do |val, server|
          @stream.started?.should be_true
        end).join
      end

      it "logs in" do
        thread = mocked_server(0, 'On')
        @stream.ready?.should == true
        thread.join
        @stream.stopped?.should == true
      end

      describe "with events turned off" do
        before { @events = false }

        it "logs in" do
          thread = mocked_server(0, 'Off')
          @stream.ready?.should == true
          thread.join
          @stream.stopped?.should == true
        end
      end

      it "sends a command after logging in" do
        action = Action.new('Command', nil, 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On') 
        thread = mocked_server(1, 'On') do |val, server|
          if val == Action.new('Login', nil, 'Username' => 'username', 'Secret' => 'pass', 'Events' => 'On').to_s
            server.send_data <<-RESPONSE
Response: Success
ActionID: actionid
Message: Authentication accepted

            RESPONSE
          else
            val.should == action.to_s
          end
        end
        @stream.ready?.should == true
        @stream.send_action action 
        thread.join
        @stream.stopped?.should == true
      end

      it "sends a command after logging in and assigns values" do
        response_resource = FutureResource.new
      #respose_resource.resource
        action = Action.new('Command', response_resource, 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On') 
        thread = mocked_server(1, 'On') do |val, server|
          if val == Action.new('Login', nil, 'Username' => 'username', 'Secret' => 'pass', 'Events' => 'On').to_s
            server.send_data <<-RESPONSE
Response: Success
ActionID: actionid
Message: Authentication accepted

            RESPONSE
          else
            val.should == action.to_s
            server.send_data <<-RESPONSE
Response: Follows
 200 foo
--END COMMAND--

            RESPONSE
#RESPONSE
#Response: Follows
#  200 result=0
#ActionID: 666
#
#            RESPONSE
 
          end
        end
        @stream.ready?.should == true
        @stream.send_action action
        p 'waiting for response_resource' 
        p response_resource.resource
        thread.join
        @stream.stopped?.should == true
      end
    end

    it 'sends events to the client when the stream is ready' do
      pending 'need to implent this functionality and refactor this test'
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
      pending 'need to implent this functionality and refactor this test'
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
      started = false
      (mocked_server(0, 'On') do |val, server|
        EM.stop
        @stream.stopped?.should be false
        @stream.unbind
        @stream.stopped?.should be true
      end).join
    end
  end
end
