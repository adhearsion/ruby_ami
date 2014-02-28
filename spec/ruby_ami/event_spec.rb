# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Event do
    subject { described_class.new 'Hangup' }

    describe "#receipt_time" do
      before do
        @now = DateTime.now
        DateTime.stub now: @now
      end

      it "should be the time the object was created (event receipt time)" do
        subject.receipt_time.should == @now
      end
    end

    context "when the event has a timestamp" do
      subject { described_class.new 'Hangup', 'Timestamp' => '1393368380.572575' }

      describe "#timestamp" do
        it "should be a time object representing the event's timestamp (assuming UTC)" do
          subject.timestamp.should == DateTime.new(2014, 2, 25, 22, 46, 20)
        end
      end

      describe "#best_time" do
        it "should be the timestamp" do
          subject.best_time.should == subject.timestamp
        end
      end
    end

    context "when the event does not have a timestamp" do
      describe "#timestamp" do
        it "should be nil" do
          subject.timestamp.should be_nil
        end
      end

      describe "#best_time" do
        it "should be the receipt_time" do
          subject.best_time.should == subject.receipt_time
        end
      end
    end

    describe "equality" do
      context "with the same name and the same headers" do
        let :event1 do
          Event.new 'Hangup',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '0'
        end

        let :event2 do
          Event.new 'Hangup',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '0'
        end

        it "should be equal" do
          event1.should be == event2
        end
      end

      context "with a different name and the same headers" do
        let :event1 do
          Event.new 'Hangup',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '0'
        end

        let :event2 do
          Event.new 'Foo',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '0'
        end

        it "should not be equal" do
          event1.should_not be == event2
        end
      end

      context "with the same name and different headers" do
        let :event1 do
          Event.new 'Hangup',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '0'
        end

        let :event2 do
          Event.new 'Hangup',
            'Channel' => 'SIP/101-3f3f',
            'Uniqueid' => '1094154427.10',
            'Cause' => '1'
        end

        it "should not be equal" do
          event1.should_not be == event2
        end
      end
    end
  end # Event
end # RubyAMI
