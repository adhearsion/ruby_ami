# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe Response do
    describe "equality" do
      context "with the same headers" do
        let :event1 do
          Response.new.tap do |e|
            e['Channel'] = 'SIP/101-3f3f'
            e['Uniqueid'] = '1094154427.10'
            e['Cause'] = '0'
          end
        end

        let :event2 do
          Response.new.tap do |e|
            e['Channel'] = 'SIP/101-3f3f'
            e['Uniqueid'] = '1094154427.10'
            e['Cause'] = '0'
          end
        end

        it "should be equal" do
          event1.should be == event2
        end
      end

      context "with different headers" do
        let :event1 do
          Response.new.tap do |e|
            e['Channel'] = 'SIP/101-3f3f'
            e['Uniqueid'] = '1094154427.10'
            e['Cause'] = '0'
          end
        end

        let :event2 do
          Response.new.tap do |e|
            e['Channel'] = 'SIP/101-3f3f'
            e['Uniqueid'] = '1094154427.10'
            e['Cause'] = '1'
          end
        end

        it "should not be equal" do
          event1.should_not be == event2
        end
      end
    end
  end # Response
end # RubyAMI
