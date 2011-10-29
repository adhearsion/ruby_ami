require 'spec_helper'

module RubyAMI
  describe Action do
    let(:name) { 'foobar' }
    let(:headers) { {'foo' => 'bar'} }

    subject { Action.new name, nil, headers }

    describe "SIPPeers actions" do
      subject { Action.new('SIPPeers', nil) }
      its(:has_causal_events?) { should be true }
    end

    describe "Queues actions" do
      subject { Action.new('Queues', nil) }
      its(:replies_with_action_id?) { should == false }
    end

    describe "IAXPeers actions" do
      before { pending }
      # FIXME: This test relies on the side effect that earlier tests have run
      # and initialized the UnsupportedActionName::UNSUPPORTED_ACTION_NAMES
      # constant for an "unknown" version of Asterisk.  This should be fixed
      # to be more specific about which version of Asterisk is under test.
      # IAXPeers is supported (with Action IDs!) since Asterisk 1.8
      subject { Action.new('IAXPeers', nil) }
      its(:replies_with_action_id?) { should == false }
    end

    describe "the ParkedCalls terminator event" do
      subject { Action.new('ParkedCalls', nil) }
      its(:causal_event_terminator_name) { should == "parkedcallscomplete" }
    end

    it "should properly convert itself into a String when additional headers are given" do
      string = Action.new("Hawtsawce", nil, "Monkey" => "Zoo").to_s
      string.should =~ /^Action: Hawtsawce\r\n/i
      string.should =~ /[^\n]\r\n\r\n$/
      string.should =~ /^(\w+:\s*[\w-]+\r\n){3}\r\n$/
    end

    it "should properly convert itself into a String when no additional headers are given" do
      Action.new("Ping", nil).to_s.should =~ /^Action: Ping\r\nActionID: [\w-]+\r\n\r\n$/i
      Action.new("ParkedCalls", nil).to_s.should =~ /^Action: ParkedCalls\r\nActionID: [\w-]+\r\n\r\n$/i
    end

    it "stores a response_resource object that has an accessor" do
      resp_resource = 'foo'
      Action.new("Ping", resp_resource).response_resource == resp_resource
    end
  end # Action
end # RubyAMI
