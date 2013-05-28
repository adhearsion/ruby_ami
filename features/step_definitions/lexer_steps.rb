Given "a new lexer" do
  @lexer = IntrospectiveManagerStreamLexer.new
  @custom_stanzas = {}
  @custom_events  = {}

  @GivenPong = lambda do |with_or_without, action_id, number|
    number = number == "a" ? 1 : number.to_i
    data = case with_or_without
      when "with"    then "Response: Pong\r\nActionID: #{action_id}\r\n\r\n"
      when "without" then "Response: Pong\r\n\r\n"
      else raise "Do not recognize preposition #{with_or_without.inspect}. Should be either 'with' or 'without'"
    end
    number.times do
      @lexer << data
    end
  end
end

Given "a version header for AMI $version" do |version|
  @lexer << "Asterisk Call Manager/1.0\r\n"
end

Given "a normal login success with events" do
  @lexer << fixture('login/standard/success')
end

Given "a normal login success with events split into two pieces" do
  stanza = fixture('login/standard/success')
  @lexer << stanza[0...3]
  @lexer << stanza[3..-1]
end

Given "a stanza break" do
  @lexer << "\r\n\r\n"
end

Given "a multi-line Response:Follows body of $method_name" do |method_name|
  multi_line_response_body = send(:follows_body_text, method_name)

  multi_line_response = format_newlines(<<-RESPONSE + "\r\n") % multi_line_response_body
Response: Follows\r
Privilege: Command\r
ActionID: 123123\r
%s\r
--END COMMAND--\r\n\r
  RESPONSE

  @lexer << multi_line_response
end

Given "a multi-line Response:Follows response simulating uptime" do
  uptime_response = "Response: Follows\r
Privilege: Command\r
System uptime: 46 minutes, 30 seconds\r
--END COMMAND--\r\n\r\n"
  @lexer << uptime_response
end

Given "syntactically invalid $name" do |name|
  @lexer << send(:syntax_error_data, name)
end

Given /^(\d+) Pong responses with an ActionID of ([\d\w.]+)$/ do |number, action_id|
  @GivenPong.call "with", action_id, number
end

Given /^a Pong response with an ActionID of ([\d\w.]+)$/ do |action_id|
  @GivenPong.call "with", action_id, 1
end

Given /^(\d+) Pong responses without an ActionID$/ do |number|
  @GivenPong.call "without", Time.now.to_f, number
end

Given /^a custom stanza named "(\w+)"$/ do |name|
  @custom_stanzas[name] = "Response: Success\r\n"
end

Given 'the custom stanza named "$name" has key "$key" with value "$value"' do |name,key,value|
  @custom_stanzas[name] << "#{key}: #{value}\r\n"
end

Given 'an AMI error whose message is "$message"' do |message|
  @lexer << "Response: Error\r\nMessage: #{message}\r\n\r\n"
end

Given 'an immediate response with text "$text"' do |text|
  @lexer << "#{text}\r\n\r\n"
end

Given 'a custom event with name "$event_name" identified by "$identifier"' do |event_name, identifer|
  @custom_events[identifer] = {:Event => event_name }
end

Given 'a custom header for event identified by "$identifier" whose key is "$key" and value is "$value"' do |identifier, key, value|
  @custom_events[identifier][key] = value
end

Given "an Authentication Required error" do
  @lexer << "Response: Error\r\nActionID: BPJeKqW2-SnVg-PyFs-vkXT-7AWVVPD0N3G7\r\nMessage: Authentication Required\r\n\r\n"
end

Given "a follows packet with a colon in it" do
  @lexer << follows_body_text("with_colon")
end

########################################
#### WHEN
########################################

When 'the custom stanza named "$name" is added to the buffer' do |name|
  @lexer << (@custom_stanzas[name] + "\r\n")
end

When 'the custom event identified by "$identifier" is added to the buffer' do |identifier|
  custom_event = @custom_events[identifier].clone
  event_name = custom_event.delete :Event
  stringified_event = "Event: #{event_name}\r\n"
  custom_event.each_pair do |key,value|
    stringified_event << "#{key}: #{value}\r\n"
  end
  stringified_event << "\r\n"
  @lexer << stringified_event
end

When "the buffer is lexed" do
  @lexer.parse_buffer
end

########################################
#### THEN
########################################

Then "the protocol should have lexed without syntax errors" do
  current_pointer     = @lexer.send(:instance_variable_get, :@current_pointer)
  data_ending_pointer = @lexer.send(:instance_variable_get, :@data_ending_pointer)
  current_pointer.should == data_ending_pointer
  @lexer.syntax_errors.size.should equal(0)
end

Then /^the protocol should have lexed with (\d+) syntax errors?$/ do |number|
  @lexer.syntax_errors.size.should == number.to_i
end

Then "the syntax error fixture named $name should have been encountered" do |name|
  irregularity = send(:syntax_error_data, name)
  @lexer.syntax_errors.find { |error| error == irregularity }.should_not be_nil
end

Then /^(\d+) messages? should have been received$/ do |number_received|
  @lexer.received_messages.size.should == number_received.to_i
end

Then /^the 'follows' body of (\d+) messages? received should equal (\w+)$/ do |number, method_name|
  multi_line_response = follows_body_text method_name
  @lexer.received_messages.should_not be_empty
  @lexer.received_messages.select do |message|
    message.text_body == multi_line_response
  end.size.should == number.to_i
end

Then "the version should be set to $version" do |version|
  @lexer.ami_version.should eql(version)
end

Then /^the ([\w\d]*) message received should have a key "([^\"]*)" with value "([^\"]*)"$/ do |ordered,key,value|
  ordered = ordered[/^(\d+)\w+$/, 1].to_i - 1
  @lexer.received_messages[ordered][key].should eql(value)
end

Then "$number AMI error should have been received" do |number|
  @lexer.ami_errors.size.should equal(number.to_i)
end

Then 'the $order AMI error should have the message "$message"' do |order, message|
  order = order[/^(\d+)\w+$/, 1].to_i - 1
  @lexer.ami_errors[order].should be_kind_of(RubyAMI::Error)
  @lexer.ami_errors[order].message.should eql(message)
end

Then '$number message should be an immediate response with text "$text"' do |number, text|
  matching_immediate_responses = @lexer.received_messages.select do |response|
    response.kind_of?(RubyAMI::Response) && response.text_body == text
  end
  matching_immediate_responses.size.should equal(number.to_i)
  matching_immediate_responses.first["ActionID"].should eql(nil)
end

Then 'the $order event should have the name "$name"' do |order, name|
  order = order[/^(\d+)\w+$/, 1].to_i - 1
  @lexer.received_messages.select do |response|
    response.kind_of?(RubyAMI::Event)
  end[order].name.should eql(name)
end

Then '$number event should have been received' do |number|
  @lexer.received_messages.select do |response|
    response.kind_of?(RubyAMI::Event)
  end.size.should equal(number.to_i)
end

Then 'the $order event should have key "$key" with value "$value"' do |order, key, value|
  order = order[/^(\d+)\w+$/, 1].to_i - 1
  @lexer.received_messages.select do |response|
    response.kind_of?(RubyAMI::Event)
  end[order][key].should eql(value)
end
