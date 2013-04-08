# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Client do
    let(:event_handler) { [] }

    let(:options) do
      {
        :host     => '127.0.0.1',
        :port     => 50000 - rand(1000),
        :username => 'username',
        :password => 'password',
        :event_handler => lambda { |event| event_handler << event }
      }
    end

    subject { Client.new options }

    it { should be_stopped }

    its(:options) { should == options }

    its(:action_queue) { should be_a GirlFriday::WorkQueue }

    its(:streams) { should == [] }

    it 'should return when the timeout option is specified and reached' do
      options[:timeout] = 2
      options[:host] = '192.0.2.1' # unreachable IP that will generally cause a timeout (RFC 5737)

      start_time = Time.now
      subject.start
      duration = Time.now - start_time

      duration.should be_between(options[:timeout], options[:timeout] + 1)
    end

    describe 'starting up' do
      before do
        ms = MockServer.new
        ms.should_receive(:receive_data).at_least :once
        s = ServerMock.new options[:host], options[:port], ms
        Thread.new { subject.start }
        sleep 0.2
      end

      it { should be_started }

      its(:events_stream)   { should be_a Stream }
      its(:actions_stream)  { should be_a Stream }
    end

    describe 'logging in streams' do
      context 'when the actions stream connects' do
        let(:mock_actions_stream) { mock 'Actions Stream' }

        let :expected_login_action do
          Action.new 'Login',
                     'Username' => 'username',
                     'Secret'   => 'password',
                     'Events'   => 'On'
        end

        before do
          Action.any_instance.stub(:response).and_return(true)
          subject.stub(:actions_stream).and_return mock_actions_stream
        end

        it 'should log in' do
          mock_actions_stream.should_receive(:send_action).with do |action|
            action.to_s.should == expected_login_action.to_s
          end

          subject.handle_message(Stream::Connected.new).join
        end
      end

      context 'when the events stream connects' do
        let(:mock_events_stream) { mock 'Events Stream' }

        let :expected_login_action do
          Action.new 'Login',
                     'Username' => 'username',
                     'Secret'   => 'password',
                     'Events'   => 'On'
        end

        before do
          subject.stub(:events_stream).and_return mock_events_stream
        end

        it 'should log in' do
          mock_events_stream.should_receive(:send_action).with expected_login_action

          subject.handle_event Stream::Connected.new

          event_handler.should be_empty
        end
      end
    end

    describe 'when the events stream disconnects' do
      it 'should stop' do
        subject.should_receive(:stop).once
        subject.handle_event Stream::Disconnected.new
        event_handler.should be_empty
      end
    end

    describe 'when the actions stream disconnects' do
      before do
        Action.any_instance.stub(:response).and_return(true)
      end

      it 'should prevent further actions being sent' do
        subject.should_receive(:_send_action).once

        GirlFriday::WorkQueue.immediate!
        subject.handle_message Stream::Connected.new
        GirlFriday::WorkQueue.queue!
        subject.handle_message Stream::Disconnected.new

        action = Action.new 'foo'
        subject.send_action action

        sleep 2

        action.should be_new
      end

      it 'should stop' do
        subject.should_receive(:stop).once
        subject.handle_message Stream::Disconnected.new
      end
    end

    describe 'when an event is received' do
      let(:event) { Event.new 'foobar' }

      it 'should call the event handler' do
        subject.handle_event event
        event_handler.should == [event]
      end
    end

    describe 'when a FullyBooted event is received on the actions connection' do
      let(:event) { Event.new 'FullyBooted' }

      let(:mock_actions_stream) { mock 'Actions Stream' }

      let :expected_login_action do
        Action.new 'Login',
                   'Username' => 'username',
                   'Secret'   => 'password',
                   'Events'   => 'On'
      end

      let :expected_events_off_action do
        Action.new 'Events', 'EventMask' => 'Off'
      end

      it 'should call the event handler' do
        subject.handle_message event
        event_handler.should == [event]
      end

      it 'should begin writing actions' do
        subject.should_receive(:start_writing_actions).once
        subject.handle_message event
      end

      it 'should turn off events' do
        Action.any_instance.stub(:response).and_return true
        subject.stub(:actions_stream).and_return mock_actions_stream

        mock_actions_stream.should_receive(:send_action).once.with expected_login_action
        mock_actions_stream.should_receive(:send_action).once.with expected_events_off_action

        login_action = subject.handle_message(Stream::Connected.new).join
        login_action.value.response = true

        subject.handle_message event
        sleep 0.5
      end
    end

    describe 'sending actions' do
      let(:action_name) { 'Login' }
      let :headers do
        {
          'Username'  => 'username',
          'Secret'    => 'password'
        }
      end
      let(:expected_action) { Action.new action_name, headers }

      let :expected_response do
        Response.new.tap do |response|
          response['ActionID'] = expected_action.action_id
          response['Message'] = 'Action completed'
        end
      end

      let(:mock_actions_stream) { mock 'Actions Stream' }

      before do
        subject.stub(:actions_stream).and_return mock_actions_stream
        subject.stub(:login_actions).and_return nil
      end

      it 'should queue up actions to be sent' do
        subject.handle_message Stream::Connected.new
        subject.action_queue.should_receive(:<<).with expected_action
        subject.send_action action_name, headers
      end

      describe 'forcibly for testing' do
        before do
          subject.actions_stream.should_receive(:send_action).with expected_action
          subject._send_action expected_action
        end

        it 'should mark the action sent' do
          expected_action.should be_sent
        end

        let(:receive_response) { subject.handle_message expected_response }

        describe 'when a response is received' do
          it 'should be sent to the action' do
            expected_action.should_receive(:<<).once.with expected_response
            receive_response
          end

          it 'should know its action' do
            receive_response
            expected_response.action.should be expected_action
          end
        end

        describe 'when an error is received' do
          let :expected_response do
            Error.new.tap do |response|
              response['ActionID'] = expected_action.action_id
              response['Message'] = 'Action failed'
            end
          end

          it 'should be sent to the action' do
            expected_action.should_receive(:<<).once.with expected_response
            receive_response
          end

          it 'should know its action' do
            receive_response
            expected_response.action.should be expected_action
          end
        end

        describe 'when an event is received' do
          let(:event) { Event.new 'foo' }

          let(:receive_event) { subject.handle_message event }

          context 'for a causal event' do
            let(:expected_action) { Action.new 'Status' }

            it 'should be sent to the action' do
              expected_action.should_receive(:<<).once.with expected_response
              expected_action.should_receive(:<<).once.with event
              receive_response
              receive_event
            end

            it 'should know its action' do
              expected_action.stub :<<
              receive_response
              receive_event
              event.action.should be expected_action
            end
          end

          context 'for a causal action which is complete' do
            let(:expected_action) { Action.new 'Status' }

            before do
              expected_action.stub(:complete?).and_return true
            end

            it 'should raise an error' do
              receive_response
              receive_event
              lambda { subject.handle_message Event.new('bar') }.should raise_error StandardError, /causal action/
            end
          end

          context 'for a non-causal action' do
            it 'should raise an error' do
              lambda { receive_event }.should raise_error StandardError, /causal action/
            end
          end
        end
      end

      describe 'from the queue' do
        it 'should send actions to the stream and set their responses' do
          subject.actions_stream.should_receive(:send_action).with expected_action
          subject.handle_message Event.new('FullyBooted')

          Thread.new do
            GirlFriday::WorkQueue.immediate!
            subject.send_action expected_action
            GirlFriday::WorkQueue.queue!
          end

          sleep 0.1

          subject.handle_message expected_response
          expected_action.response.should be expected_response
        end

        it 'should not send another action if the first action has not yet received a response' do
          subject.actions_stream.should_receive(:send_action).once.with expected_action
          subject.handle_message Event.new('FullyBooted')
          actions = []

          2.times do
            action = Action.new action_name, headers
            actions << action
            subject.send_action action
          end

          sleep 2

          actions.should have(2).actions
          actions[0].should be_sent
          actions[1].should be_new
        end
      end
    end

    describe '#stop' do
      let(:mock_actions_stream) { mock 'Actions Stream', :alive? => true }
      let(:mock_events_stream) { mock 'Events Stream', :alive? => true }

      let(:streams) { [mock_actions_stream, mock_events_stream] }

      before do
        subject.stub(:actions_stream).and_return mock_actions_stream
        subject.stub(:events_stream).and_return mock_events_stream
      end

      it 'should close both streams' do
        streams.each { |s| s.should_receive :terminate }
        subject.stop
      end
    end
  end
end
