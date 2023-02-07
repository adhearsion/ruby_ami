# encoding: utf-8
require 'spec_helper'

RSpec.describe RubyAMI::Response do
  describe "#text_body" do
    it "is the text body that was passed in" do
      response = described_class.new
      response.text_body = "Expected text body"
      expect(response.text_body).to eq "Expected text body"
    end

    it "is the output when no text body was passed in" do
      headers = { "Output" => "Expected text body from output" }
      response = described_class.new(headers)
      expect(response.text_body).to eq "Expected text body from output"
    end
  end

  describe "equality" do
    context "with the same headers" do
      let :event1 do
        described_class.new 'Channel' => 'SIP/101-3f3f',
                     'Uniqueid' => '1094154427.10',
                     'Cause' => '0'
      end

      let :event2 do
        described_class.new 'Channel' => 'SIP/101-3f3f',
                     'Uniqueid' => '1094154427.10',
                     'Cause' => '0'
      end

      it "should be equal" do
        event1.should be == event2
      end
    end

    context "with different headers" do
      let :event1 do
        described_class.new 'Channel' => 'SIP/101-3f3f',
                     'Uniqueid' => '1094154427.10',
                     'Cause' => '0'
      end

      let :event2 do
        described_class.new 'Channel' => 'SIP/101-3f3f',
                     'Uniqueid' => '1094154427.10',
                     'Cause' => '1'
      end

      it "should not be equal" do
        event1.should_not be == event2
      end
    end
  end
end
