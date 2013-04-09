# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Stream do
    let(:server_port) { 50000 - rand(1000) }

    def client
      @client ||= mock('Client')
    end

    before do
      def client.message_received(message)
        @messages ||= Queue.new
        @messages << message
      end

      def client.messages
        @messages
      end
    end

    let :client_messages do
      messages = []
      messages << client.messages.pop until client.messages.empty?
      messages
    end

    def mocked_server(times = nil, fake_client = nil, &block)
      mock_target = MockServer.new
      mock_target.should_receive(:receive_data).send(*(times ? [:exactly, times] : [:at_least, 1])).with &block
      s = ServerMock.new '127.0.0.1', server_port, mock_target
      @stream = Stream.new '127.0.0.1', server_port, lambda { |m| client.message_received m }
      @stream.async.run
      fake_client.call if fake_client.respond_to? :call
      Celluloid::Actor.join s
      Timeout.timeout 5 do
        Celluloid::Actor.join @stream
      end
    end

    def expect_connected_event
      client.should_receive(:message_received).with Stream::Connected.new
    end

    def expect_disconnected_event
      client.should_receive(:message_received).with Stream::Disconnected.new
    end

    before { @sequence = 1 }

    describe "after connection" do
      it "should be started" do
        expect_connected_event
        expect_disconnected_event
        mocked_server 0, -> { @stream.started?.should be_true }
      end

      it "can send an action" do
        expect_connected_event
        expect_disconnected_event
        action = Action.new('Command', 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On')
        mocked_server(1, lambda { @stream.send_action action }) do |val, server|
          val.should == action.to_s

          server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Recording started

          EVENT
        end
      end

      it "can send an action by properties" do
        expect_connected_event
        expect_disconnected_event
        action = Action.new('Command', 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On')
        mocked_server(1, lambda { @stream.send_action('Command', 'Command' => 'RECORD FILE evil', 'ActionID' => 666, 'Events' => 'On') }) do |val, server|
          val.should == action.to_s

          server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Recording started

          EVENT
        end
      end
    end

    it 'sends events to the client when the stream is ready' do
      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        server.send_data <<-EVENT
Event: Hangup
Channel: SIP/101-3f3f
Uniqueid: 1094154427.10
Cause: 0

        EVENT
      end

      client_messages.should be == [
        Stream::Connected.new,
        Event.new('Hangup', 'Channel' => 'SIP/101-3f3f', 'Uniqueid' => '1094154427.10', 'Cause' => '0'),
        Stream::Disconnected.new
      ]
    end

    describe 'when a response is received' do
      before do
        expect_connected_event
        expect_disconnected_event
      end

      let(:action) { Action.new 'Command', 'Command' => 'RECORD FILE evil' }

      it 'should be set on the action' do
        mocked_server(1, lambda { @stream.send_action action }) do |val, server|
          val.should == action.to_s

          server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Recording started

          EVENT
        end

        action.response(1).should == Response.new('ActionID' => action.action_id, 'Message' => 'Recording started')
      end

      it 'should be returned from #send_action' do
        response = nil
        mocked_server(1, lambda { response = @stream.send_action action }) do |val, server|
          val.should == action.to_s

          server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Recording started

          EVENT
        end

        response.should == Response.new('ActionID' => action.action_id, 'Message' => 'Recording started')
      end

      describe 'when it is an error' do
        it 'should be set on the action' do
          send_action = lambda do
            expect { @stream.send_action action }.to raise_error(RubyAMI::Error, 'Action failed')
            @stream.should be_alive
          end

          mocked_server(1, send_action) do |val, server|
            val.should == action.to_s

            server.send_data <<-EVENT
Response: Error
ActionID: #{action.action_id}
Message: Action failed

            EVENT
          end

          expect { action.response 1 }.to raise_error(RubyAMI::Error, 'Action failed')
        end
      end

      describe 'for a causal action' do
        let(:action) { Action.new 'sippeers' }

        it "should not immediately set the action's response" do
          mocked_server(1, lambda { @stream.async.send_action action }) do |val, server|
            val.should == action.to_s

            server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Events to follow

            EVENT
          end

          expect { action.response 1 }.to raise_error(Timeout::Error)
        end

        describe "followed by events" do
          it "should add events to the action, but not yet set the response" do
            mocked_server(1, lambda { @stream.async.send_action action }) do |val, server|
              val.should == action.to_s

              server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Events to follow

Event: PeerEntry
ActionID: #{action.action_id}
Channeltype: SIP
ObjectName: usera

              EVENT
            end

            action.events.should eql([
              Event.new('PeerEntry', 'ActionID' => action.action_id, 'Channeltype' => 'SIP', 'ObjectName' => 'usera')
            ])

            expect { action.response 1 }.to raise_error(Timeout::Error)
          end

          context "and a terminator event" do
            let :expected_events do
              [
                Event.new('PeerEntry', 'ActionID' => action.action_id, 'Channeltype' => 'SIP', 'ObjectName' => 'usera'),
                Event.new('PeerlistComplete', 'ActionID' => action.action_id, 'EventList' => 'Complete', 'ListItems' => '2')
              ]
            end

            let :expected_response do
              Response.new('ActionID' => action.action_id, 'Message' => 'Events to follow').tap do |response|
                response.events = expected_events
              end
            end

            it "should add events to the action, and set the response" do
              response = nil
              mocked_server(1, lambda { response = @stream.send_action action }) do |val, server|
                val.should == action.to_s

                server.send_data <<-EVENT
Response: Success
ActionID: #{action.action_id}
Message: Events to follow

Event: PeerEntry
ActionID: #{action.action_id}
Channeltype: SIP
ObjectName: usera

Event: PeerlistComplete
EventList: Complete
ListItems: 2
ActionID: #{action.action_id}

                EVENT
              end

              response.should == expected_response
              action.response(1).should == expected_response
            end
          end
        end
      end
    end

    it 'puts itself in the stopped state and fires a disconnected event when unbound' do
      expect_connected_event
      expect_disconnected_event
      mocked_server(1, lambda { @stream.send_data 'Foo' }) do |val, server|
        @stream.stopped?.should be false
      end
      @stream.alive?.should be false
    end
  end
end
