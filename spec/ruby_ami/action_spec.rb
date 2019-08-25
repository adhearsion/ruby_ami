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

    it { is_expected.not_to be_complete }

    describe "SIPPeers actions" do
      it "has causal events" do
        expect(Action.new('SIPPeers').has_causal_events?).to be true
      end
    end

    describe "the ParkedCalls terminator event" do
      it "knows its causal event terminator name" do
        expect(Action.new('ParkedCalls').causal_event_terminator_name).to eq("parkedcallscomplete")
      end
    end

    it "should properly convert itself into a String when additional headers are given" do
      string = Action.new("Hawtsawce", "Monkey" => "Zoo").to_s
      expect(string).to match(/^Action: Hawtsawce\r\n/i)
      expect(string).to match(/[^\n]\r\n\r\n$/)
      expect(string).to match(/^(\w+:\s*[\w-]+\r\n){3}\r\n$/)
    end

    it "should properly convert itself into a String when no additional headers are given" do
      expect(Action.new("Ping").to_s).to match(/^Action: Ping\r\nActionID: [\w-]+\r\n\r\n$/i)
      expect(Action.new("ParkedCalls").to_s).to match(/^Action: ParkedCalls\r\nActionID: [\w-]+\r\n\r\n$/i)
    end

    describe '#<<' do
      describe 'for a non-causal action' do
        context 'with a response' do
          let(:response) { Response.new }

          before { subject << response }

          it 'should set the response' do
            expect(subject.response).to be response
          end

          it 'should call the callback' do
            expect(@callback_result).to be response
          end

          it { is_expected.to be_complete }
        end

        context 'with an error' do
          let(:error) { Error.new.tap { |e| e.message = 'AMI error' } }

          before { subject << error }

          it 'should set the response' do
            expect(subject.response).to eq(error)
          end

          it { is_expected.to be_complete }
        end

        context 'with an event' do
          it 'should raise an error' do
            expect { subject << Event.new('foo') }.to raise_error StandardError, /causal action/
          end
        end
      end

      describe 'for a causal action' do
        let(:name) { 'Status' }
        let(:response) { Response.new }

        context 'with a response' do
          before { subject << response }

          it { is_expected.not_to be_complete }
        end

        context 'with an event' do
          let(:event) { Event.new 'foo' }

          before { subject << response << event }

          it "should add the events to the response" do
            expect(subject.response.events).to eq([event])
          end
        end

        context 'with a terminating event' do
          let(:event) { Event.new 'StatusComplete' }

          before do
            subject << response
            expect(subject).not_to be_complete
            subject << event
          end

          it "should add the events to the response" do
            expect(subject.response.events).to eq([event])
          end

          it { is_expected.to be_complete }

          it { expect(subject.response).to be response }
        end
      end
    end

    describe 'comparison' do
      describe 'with another Action' do
        context 'with identical name and headers' do
          let(:other) { Action.new name, headers }
          it { is_expected.to eq(other) }
        end

        context 'with identical name and different headers' do
          let(:other) { Action.new name, 'boo' => 'baz' }
          it { is_expected.not_to eq(other) }
        end

        context 'with different name and identical headers' do
          let(:other) { Action.new 'BARBAZ', headers }
          it { is_expected.not_to eq(other) }
        end
      end

      it { is_expected.not_to eq(:foo) }
    end
  end # Action
end # RubyAMI
