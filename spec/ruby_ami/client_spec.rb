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

    its(:events_stream)   { should be_a Stream }
    its(:actions_stream)  { should be_a Stream }

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
        subject.async.start
        sleep 0.2
      end

      it { should be_started }
    end

    describe 'logging in streams' do
      context 'when the actions stream connects' do
        let(:mock_actions_stream) { mock 'Actions Stream' }

        before do
          subject.wrapped_object.stub(:actions_stream).and_return mock_actions_stream
        end

        it 'should disable events' do
          mock_actions_stream.should_receive(:send_action).with 'Events', 'EventMask' => 'Off'

          subject.handle_message Stream::Connected.new
        end
      end
    end

    describe 'when the events stream disconnects' do
      it 'should shut down the client' do
        subject.events_stream.terminate
        sleep 0.2
        subject.alive?.should be_false
      end
    end

    describe 'when the actions stream disconnects' do
      it 'should shut down the client' do
        subject.actions_stream.terminate
        sleep 0.2
        subject.alive?.should be_false
      end
    end

    describe 'when an event is received' do
      let(:event) { Event.new 'foobar' }

      it 'should call the event handler' do
        subject.handle_event event
        event_handler.should == [event]
      end
    end
  end
end
