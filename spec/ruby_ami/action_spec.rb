require 'spec_helper'

module RubyAMI
  describe Action do
    let(:name) { 'foobar' }
    let(:headers) { {'foo' => 'bar'} }

    subject { Action.new name, headers }

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

    describe "a block passed to #new" do
      subject do
        Action.new("Ping") do |response|
          @callback_called = true
          @callback_value = response
        end
      end

      it "should be called when its response is set" do
        response = Response.new
        subject.future_resource.resource = response
        subject.response
        @callback_called.should be_true
        @callback_value.should == response
      end
    end
  end # Action
end # RubyAMI
