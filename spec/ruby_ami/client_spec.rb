require 'spec_helper'

module RubyAMI
  describe Client do
    let(:options) do
      {
        :server   => '127.0.0.1',
        :port     => 5038,
        :username => 'username',
        :password => 'password'
      }
    end

    subject { Client.new options }

    it { should be_stopped }

    its(:options) { should == options }

    its(:action_queue) { should be_a GirlFriday::WorkQueue }

    describe 'starting up' do
      before do
        subject.start do
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

    describe 'sending actions' do
      let(:action_name) { 'Login' }
      let :headers do
        {
          'Username'  => 'username',
          'Secret'    => 'password'
        }
      end
      let(:expected_action) { Action.new action_name, headers }

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

      describe 'from the queue' do
        it 'should send actions to the stream and set their responses' do
          subject.actions_stream.expects(:send_action).with expected_action
          subject.handle_message Stream::Connected.new

          send_thread = Thread.new do
            GirlFriday::WorkQueue.immediate!
            subject.send_action expected_action
            GirlFriday::WorkQueue.queue!
          end

          sleep 0.1

          response = Response.new
          response['ActionID'] = expected_action.action_id
          response['Message'] = 'Action completed'

          subject.handle_message response
          send_thread.join
          expected_action.response.should be response
        end

      end
    end

    it "can send multiple messages from different processes and receive responses"
  end
end
