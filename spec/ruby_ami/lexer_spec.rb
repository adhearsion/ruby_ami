# encoding: utf-8
require 'spec_helper'

RSpec.describe RubyAMI::Lexer do
  context "Asterisk 13" do
    context "when a follows is received" do
      it "parses and emits the message" do
        raw_message = [
          "Response: Follows",
          "Privilege: Command",
          "ActionID: 5dc113e8-96ce-426f-b3f9-f2d58742e7f0",
          "Extension 1@adhearsion-redirect with priority 1 already exists",
          "Command 'dialplan add extension 1,1,AGI,agi:async into adhearsion-redirect' failed.",
          "--END COMMAND--",
          ""
        ]

        expected_message = nil
        delegate = double("RubyAMI::Stream")
        allow(delegate).to receive(:message_received) { |msg| expected_message = msg }
        lexer = described_class.new(delegate)

        raw_message.each do |line|
          lexer << line + "\r\n"
        end

        expect(expected_message.text_body).to eq "Extension 1@adhearsion-redirect with priority 1 already exists\r\nCommand 'dialplan add extension 1,1,AGI,agi:async into adhearsion-redirect' failed."
      end
    end
  end

  context "Asterisk 14+" do
    context "when an error is received" do
      it "parses and emits the error" do
        raw_message = [
          "Response: Error",
          "ActionID: 97dfa797-e972-4de8-b592-8f7060a816a5",
          "Message: Command output follows",
          "Output: Extension 1@adhearsion-redirect with priority 1 already exists",
          "Output: Command 'dialplan add extension 1,1,AGI,agi:async into adhearsion-redirect' failed.",
          ""
        ]

        expected_error = nil
        delegate = double("RubyAMI::Stream")
        allow(delegate).to receive(:error_received) do |error|
          expected_error = error
        end
        lexer = described_class.new(delegate)

        raw_message.each do |line|
          lexer << line + "\r\n"
        end

        expect(expected_error.text_body).to eq "Extension 1@adhearsion-redirect with priority 1 already exists\r\nCommand 'dialplan add extension 1,1,AGI,agi:async into adhearsion-redirect' failed."
      end
    end

    context "when a message is received" do
      it "parses and emits the response" do
        raw_message = [
          "Response: Success",
          "ActionID: d5fb2d8b-7f15-43e6-bd35-33585abd24d6",
          "Message: Command output follows",
          "Output: Channel              Location             State   Application(Data)             ",
          "Output: 0 active channels",
          "Output: 0 active calls",
          "Output: 0 calls processed",
          ""
        ]

        expected_message = nil
        delegate = double("RubyAMI::Stream")
        allow(delegate).to receive(:message_received) do |message|
          expected_message = message
        end
        lexer = described_class.new(delegate)

        raw_message.each do |line|
          lexer << line + "\r\n"
        end

        expect(expected_message.text_body).to eq "Channel              Location             State   Application(Data)             \r\n0 active channels\r\n0 active calls\r\n0 calls processed"
      end
    end
  end
end
