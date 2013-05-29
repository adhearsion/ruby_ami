#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'ruby_ami'
require 'benchmark/ips'

class LexerHost
  def initialize
    @lexer = RubyAMI::Lexer.new self
  end

  def receive_data(data)
    @lexer << data
  end

  def message_received(message)
  end

  def error_received(error)
  end

  def syntax_error_encountered(ignored_chunk)
  end
end

lexer_host = LexerHost.new

event = <<-EVENT
Event: Dial
SubEvent: <value>
Channel: <value>
Destination: <value>
CallerIDNum: <value>
CallerIDName: <value>
ConnectedLineNum: <value>
ConnectedLineName: <value>
UniqueID: <value>
DestUniqueID: <value>
Dialstring: <value>

EVENT
event.gsub!("\n", "\r\n")

Benchmark.ips do |ips|
  ips.report("event lexing") { lexer_host.receive_data event }
end
