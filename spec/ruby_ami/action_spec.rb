# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Action do
    let(:name) { 'foobar' }
    let(:headers) { {'foo' => 'bar'} }

    subject do
      described_class.new name, headers do |response|
        @callback_result = response
      end
    end

    it { should_not be_complete }

    describe "SIPPeers actions" do
      subject { Action.new('SIPPeers') }
      its(:has_causal_events?) { should be true }
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

    describe '#<<' do
      describe 'for a non-causal action' do
        context 'with a response' do
          let(:response) { Response.new }

          before { subject << response }

          it 'should set the response' do
            subject.response.should be response
          end

          it 'should call the callback' do
            @callback_result.should be response
          end

          it { should be_complete }
        end

        context 'with an error' do
          let(:error) { Error.new.tap { |e| e.message = 'AMI error' } }

          before { subject << error }

          it 'should set the response' do
            subject.response.should == error
          end

          it { should be_complete }
        end

        context 'with an event' do
          it 'should raise an error' do
            lambda { subject << Event.new('foo') }.should raise_error StandardError, /causal action/
          end
        end
      end

      describe 'for a causal action' do
        let(:name) { 'Status' }
        let(:response) { Response.new }

        context 'with a response' do
          before { subject << response }

          it { should_not be_complete }
        end

        context 'with an event' do
          let(:event) { Event.new 'foo' }

          before { subject << response << event }

          it "should add the events to the response" do
            subject.response.events.should == [event]
          end
        end

        context 'with a terminating event' do
          let(:event) { Event.new 'StatusComplete' }

          before do
            subject << response
            subject.should_not be_complete
            subject << event
          end

          it "should add the events to the response" do
            subject.response.events.should == [event]
          end

          it { should be_complete }

          its(:response) { should be response }
        end
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
