# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Event do
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
