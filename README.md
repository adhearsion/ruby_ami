# RubyAMI
RubyAMI is an AMI client library in Ruby and based on EventMachine with the sole purpose of providing an connection to the Asterisk Manager Interface. RubyAMI does not provide any features beyond connection management and protocol parsing. Actions are sent over the wire, and responses come back via callbacks. It's up to you to match these up into something useful. In this regard, RubyAMI is very similar to [Blather](https://github.com/sprsquish/blather) for XMPP or [Punchblock](https://github.com/adhearsion/punchblock), the Ruby 3PCC library. In fact, Punchblock uses RubyAMI under the covers for its Asterisk implementation, including an implementation of AsyncAGI.

## Installation
    gem install ruby_ami

## Usage
```ruby
require 'ruby_ami'

class MyAMIClient < RubyAMI::Client
  def on_connect
    puts "AMI Connected successfully"
    write_action "Originate", ...some options...
  end

  def handle_event(event)
    puts "Received an AMI event: #{event}"
  end

  def handle_error(error)
    ...similar here...
  end

  def handle_response(response)
    ...similar here...
  end
end

EM.run { MyAMIClient.run '127.0.0.1', 5038, 'admin', 'password' }
```

## Links:
* [Source](https://github.com/adhearsion/ruby_ami)
* [Documentation](http://rdoc.info/github/adhearsion/ruby_ami/master/frames)
* [Bug Tracker](https://github.com/adhearsion/ruby_ami/issues)

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  * If you want to have your own version, that is fine but bump version in a commit by itself so I can ignore when I pull
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Ben Langfeld, Jay Phillips. MIT licence (see LICENSE for details).
