require 'spec_helper'

module RubyAMI
  describe Client do
    let(:event_handler) { [] }

    let(:options) do
      {
        :server   => '127.0.0.1',
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

    describe 'starting up' do
      before do
        MockServer.any_instance.stubs :receive_data
        subject.start do
          EM.start_server options[:server], options[:port], ServerMock
          EM.add_timer(0.5) { EM.stop if EM.reactor_running? }
        end
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
                     'Events'   => 'Off'
        end

        before do
          Action.any_instance.stubs(:response).returns(true)
          subject.stubs(:actions_stream).returns mock_actions_stream
        end

        it 'should log in' do
          mock_actions_stream.expects(:send_action).with do |action|
            action.to_s.should == expected_login_action.to_s
          end

          GirlFriday::WorkQueue.immediate!
          subject.handle_message Stream::Connected.new
          GirlFriday::WorkQueue.queue!
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
          subject.stubs(:events_stream).returns mock_events_stream
        end

        it 'should log in' do
          mock_events_stream.expects(:send_action).with do |action|
            action.to_s.should == expected_login_action.to_s
          end

          subject.handle_event Stream::Connected.new
        end
      end
    end

    describe 'when an event is received' do
      let(:event) { Event.new 'foobar' }

      it 'should call the event handler' do
        subject.handle_event event
        event_handler.should == [event]
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
        subject.stubs(:actions_stream).returns mock_actions_stream
        subject.stubs(:login_actions).returns nil
      end

      it 'should queue up actions to be sent' do
        subject.handle_message Stream::Connected.new
        subject.action_queue.expects(:<<).with expected_action
        subject.send_action action_name, headers
      end

      describe 'forcibly for testing' do
        before do
          subject.actions_stream.expects(:send_action).with expected_action
          subject._send_action expected_action
        end

        it 'should mark the action sent' do
          expected_action.should be_sent
        end

        let(:receive_response) { subject.handle_message expected_response }

        describe 'when a response is received' do
          it 'should be sent to the action' do
            expected_action.expects(:<<).once.with expected_response
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
              expected_action.expects(:<<).once.with expected_response
              expected_action.expects(:<<).once.with event
              receive_response
              receive_event
            end

            it 'should know its action' do
              expected_action.stubs :<<
              receive_response
              receive_event
              event.action.should be expected_action
            end
          end

          context 'for a causal action which is complete' do
            let(:expected_action) { Action.new 'Status' }

            before do
              expected_action.stubs(:complete?).returns true
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
          subject.actions_stream.expects(:send_action).with expected_action
          subject.handle_message Stream::Connected.new

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
          subject.actions_stream.expects(:send_action).once.with expected_action
          subject.handle_message Stream::Connected.new
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
  end
end
