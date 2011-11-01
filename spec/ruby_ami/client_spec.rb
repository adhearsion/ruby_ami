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

    its(:action_queue) { should be_a Queue }
    its(:action_queue) { should be_empty }

    describe 'starting up' do
      before do
        @em_thread = Thread.new do
          subject.start
        end
        sleep 1
      end

      it { should be_started }

      its(:events_stream)   { should be_a Stream }
      its(:actions_stream)  { should be_a Stream }

      after { @em_thread.kill if @em_thread }
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

          subject.handle_message Stream::Connected.new
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

      it 'should queue up actions to be sent' do
        subject.send_action action_name, headers
        subject.action_queue.pop(true).to_s.should == expected_action.to_s
      end
    end

    it "can send multiple messages from different processes and receive responses"
  end
end
