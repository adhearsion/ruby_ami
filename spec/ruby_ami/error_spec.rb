# encoding: utf-8
require 'spec_helper'

RSpec.describe RubyAMI::Error do
  describe "#text_body" do
    it "is the output header" do
      headers = { 'Output' => 'Expected output' }
      obj = described_class.new(headers)

      expect(obj.text_body).to eq 'Expected output'
    end
  end
end
