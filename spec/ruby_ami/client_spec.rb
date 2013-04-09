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

    its(:streams) { should == [] }

    it 'should return when the timeout option is specified and reached' do
      pending
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
          subject.wrapped_object.stub(:actions_stream).and_return mock_actions_stream
        end

        it 'should log in' do
          mock_actions_stream.should_receive(:send_action).with do |action|
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
          subject.wrapped_object.stub(:events_stream).and_return mock_events_stream
        end

        it 'should log in' do
          mock_events_stream.should_receive(:send_action).with expected_login_action

          subject.handle_event Stream::Connected.new

          event_handler.should be_empty
        end
      end
    end

    describe 'when the events stream disconnects' do
      it 'should shut down the client' do
        subject.handle_event Stream::Disconnected.new
        subject.should_not be_alive
      end
    end

    describe 'when the actions stream disconnects' do
      it 'should shut down the client' do
        subject.handle_message Stream::Disconnected.new
        subject.should_not be_alive
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

      it 'should turn off events' do
        Action.any_instance.stub(:response).and_return true
        subject.wrapped_object.stub(:actions_stream).and_return mock_actions_stream

        mock_actions_stream.should_receive(:send_action).once.with expected_login_action
        mock_actions_stream.should_receive(:send_action).once.with expected_events_off_action

        login_action = subject.handle_message Stream::Connected.new
        login_action.response = true

        subject.handle_message event
        sleep 0.5
      end
    end
  end
end
