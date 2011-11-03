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
      let(:message) { :bar }

      it 'should set the response' do
        subject << message
        subject.response.should be message
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
