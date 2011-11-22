require 'spec_helper'

module RubyAMI
  describe Action do
    let(:name) { 'foobar' }
    let(:headers) { {'foo' => 'bar'} }

    subject do
      Action.new name, headers do |response|
        @foo = response
      end
    end

    it { should be_new }

    describe "SIPPeers actions" do
      subject { Action.new('SIPPeers') }
      its(:has_causal_events?) { should be true }
    end

    describe "Queues actions" do
      subject { Action.new('Queues') }
      its(:replies_with_action_id?) { should == false }
    end

    describe "IAXPeers actions" do
      before { pending }
      # FIXME: This test relies on the side effect that earlier tests have run
      # and initialized the UnsupportedActionName::UNSUPPORTED_ACTION_NAMES
      # constant for an "unknown" version of Asterisk.  This should be fixed
      # to be more specific about which version of Asterisk is under test.
      # IAXPeers is supported (with Action IDs!) since Asterisk 1.8
      subject { Action.new('IAXPeers') }
      its(:replies_with_action_id?) { should == false }
    end

    describe "the ParkedCalls terminator event" do
      subject { Action.new('ParkedCalls') }
      its(:causal_event_terminator_name) { should == "parkedcallscomplete" }
    end

    it "should properly convert itself into a String when additional headers are given" do
      string = Action.new("Hawtsawce", "Monkey" => "Zoo").to_s
      string.should =~ /^Action: Hawtsawce\r\n/i
      string.should =~ /[^\n]\r\n\r\n$/
      string.should =~ /^(\w+:\s*[\w-]+\r\n){3}\r\n$/
    end

    it "should properly convert itself into a String when no additional headers are given" do
      Action.new("Ping").to_s.should =~ /^Action: Ping\r\nActionID: [\w-]+\r\n\r\n$/i
      Action.new("ParkedCalls").to_s.should =~ /^Action: ParkedCalls\r\nActionID: [\w-]+\r\n\r\n$/i
    end

    it 'should be able to be marked as sent' do
      subject.state = :sent
      subject.should be_sent
    end

    it 'should be able to be marked as complete' do
      subject.state = :complete
      subject.should be_complete
    end

    describe '#<<' do
      describe 'for a non-causal action' do
        context 'with a response' do
          let(:response) { Response.new }

          it 'should set the response' do
            subject << response
            subject.response.should be response
          end
        end

        context 'with an error' do
          let(:error) { Error.new.tap { |e| e.message = 'AMI error' } }

          it 'should set the response and raise the error when reading it' do
            subject << error
            lambda { subject.response }.should raise_error Error, 'AMI error'
          end
        end

        context 'with an event' do
          it 'should raise an error' do
            lambda { subject << Event.new('foo') }.should raise_error StandardError, /causal action/
          end
        end
      end

      describe 'for a causal action' do
        let(:name) { 'Status' }

        context 'with a response' do
          let(:message) { Response.new }

          before { subject << message }

          it { should_not be_complete }
        end

        context 'with an event' do
          let(:event) { Event.new 'foo' }

          before { subject << event }

          its(:events) { should == [event] }
        end

        context 'with a terminating event' do
          let(:response)  { Response.new }
          let(:event)     { Event.new 'StatusComplete' }

          before do
            subject << response
            subject.should_not be_complete
            subject << event
          end

          its(:events) { should == [event] }

          it { should be_complete }

          its(:response) { should be response }
        end
      end
    end

    describe 'setting the response' do
      let(:response) { :bar }

      before { subject.response = response }

      it { should be_complete }
      its(:response) { should == response }

      it 'should call the response callback with the response' do
        @foo.should == response
      end
    end

    describe 'comparison' do
      describe 'with another Action' do
        context 'with identical name and headers' do
          let(:other) { Action.new name, headers }
          it { should == other }
        end

        context 'with identical name and different headers' do
          let(:other) { Action.new name, 'boo' => 'baz' }
          it { should_not == other }
        end

        context 'with different name and identical headers' do
          let(:other) { Action.new 'BARBAZ', headers }
          it { should_not == other }
        end
      end

      it { should_not == :foo }
    end
  end # Action
end # RubyAMI
