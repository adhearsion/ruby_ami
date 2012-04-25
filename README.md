# RubyAMI [![Build Status](https://secure.travis-ci.org/adhearsion/ruby_ami.png?branch=master)](http://travis-ci.org/adhearsion/ruby_ami)
RubyAMI is an AMI client library in Ruby and based on EventMachine with the sole purpose of providing an connection to the Asterisk Manager Interface. RubyAMI does not provide any features beyond connection management and protocol parsing. Actions are sent over the wire, and responses come back via callbacks. It's up to you to match these up into something useful. In this regard, RubyAMI is very similar to [Blather](https://github.com/sprsquish/blather) for XMPP or [Punchblock](https://github.com/adhearsion/punchblock), the Ruby 3PCC library. In fact, Punchblock uses RubyAMI under the covers for its Asterisk implementation, including an implementation of AsyncAGI.

## Installation
    gem install ruby_ami

## Usage
```ruby
require 'ruby_ami'

include RubyAMI

client = Client.new :username       => 'test',
                    :password       => 'test',
                    :host           => '127.0.0.1',
                    :port           => 5038,
                    :event_handler  => lambda { |e| handle_event e },
                    :logger         => Logger.new('ruby_ami.log')

def handle_event(event)
  case event.name
  when 'FullyBooted'
    client.send_action 'Originate', 'Channel' => 'SIP/foo'
  end
end

client.start
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
