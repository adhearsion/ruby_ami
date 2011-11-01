require 'spec_helper'

module RubyAMI
  describe Login do

    it "logs in after starting up each stream" do
      @stream_mock = stub_everything('Stream')
      response = Response.new
      response['ActionID'] = 'dead puppies'
      response['Message'] = "aren't much fun"
      @stream_mock.expects(:send_command).with(){|login_action| 
        @code_to_call.call response
        login_action.name.should == 'login'
        login_action.headers.should == Action.new('Login', nil, 'Username' => 'mike', 'Secret' => 'roch', 'Events' => 'Off').headers
      }
      response_queue = Queue.new
      Stream.expects(:start).with(){|server, port, block| 
        server.should == '127.0.0.1'
        port.should == '666'  
        @code_to_call = block}.returns(@stream_mock)
      Login.connection(:server => '127.0.0.1', :port =>'666', 'Username' => 'mike', 'Secret' => 'roch', 'Events' => 'Off', 'Queue' => response_queue).should be @stream_mock
    end

  end
end

