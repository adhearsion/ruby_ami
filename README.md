# RubyAMI

[![Gem Version](https://badge.fury.io/rb/ruby_ami.png)](https://rubygems.org/gems/ruby_ami)
[![Build Status](https://secure.travis-ci.org/adhearsion/ruby_ami.png?branch=develop)](http://travis-ci.org/adhearsion/ruby_ami)
[![Dependency Status](https://gemnasium.com/adhearsion/ruby_ami.png?travis)](https://gemnasium.com/adhearsion/ruby_ami)
[![Code Climate](https://codeclimate.com/github/adhearsion/ruby_ami.png)](https://codeclimate.com/github/adhearsion/ruby_ami)
[![Coverage Status](https://coveralls.io/repos/adhearsion/ruby_ami/badge.png?branch=develop)](https://coveralls.io/r/adhearsion/ruby_ami)
[![Inline docs](http://inch-ci.org/github/adhearsion/ruby_ami.png?branch=develop)](http://inch-ci.org/github/adhearsion/ruby_ami)

RubyAMI is an AMI client library in Ruby based on Celluloid with the sole purpose of providing a connection to the Asterisk Manager Interface. RubyAMI does not provide any features beyond connection management and protocol parsing. Actions are sent over the wire, and responses are returned. Events are passed to a callback you define. It's up to you to match these up into something useful. In this regard, RubyAMI is very similar to [Blather](https://github.com/sprsquish/blather) for XMPP or [Punchblock](https://github.com/adhearsion/punchblock), the Ruby 3PCC library. In fact, Punchblock uses RubyAMI under the covers for its Asterisk implementation, including an implementation of AsyncAGI.

NB: If you're looking to develop an application on Asterisk, you should take a look at the [Adhearsion](http://adhearsion.com) framework first. This library is much lower level.

## Installation
    gem install ruby_ami

## Usage

In order to setup a connection to listen for AMI events, one can do:

```ruby
require 'ruby_ami'

def handle_event(event)
  case event.name
  when 'FullyBooted'
    puts "The server booted and is available for commands."
  else
    puts "Received an event from Asterisk: #{event.inspect}"
  end
end

stream = RubyAMI::Stream.new '127.0.0.1', 5038, 'manager', 'password',
                              ->(e) { handle_event e },
                              Logger.new(STDOUT), 10

Celluloid.join(stream) # This will block until the actor is terminated elsewhere. Otherwise, the actor will run in its own thread allowing other work to be done here.
```

Note that using `Stream.new`, the actor will shut down when the connection is lost (and in this case the program will exit). If it is necessary to restart the actor on failure, you can start it in a Celluloid supervisor:

```ruby
RubyAMI::Stream.supervise_as :ami_connection, '127.0.0.1', 5038, 'manager', 'password',
                              ->(e) { handle_event e },
                              Logger.new(STDOUT), 10
```

It is also possible to execute actions in response to events:

```ruby
require 'ruby_ami'

def handle_event(event, stream)
  case event.name
  when 'FullyBooted'
    puts "The connection was successful. Originating a call."
    response = stream.send_action 'Originate', 'Channel' => 'SIP/foo'
    puts "The call origination resulted in #{response.inspect}"
  end
end

stream = RubyAMI::Stream.new '127.0.0.1', 5038, 'manager', 'password',
                              ->(e) { handle_event e },
                              Logger.new(STDOUT), 10

Celluloid.join(stream) # This will block until the actor is terminated elsewhere. Otherwise, the actor will run in its own thread allowing other work to be done here.
```

Executing actions does not strictly have to be done within the event handler, but it is not valid to send AMI events before receiving a `FullyBooted` event. If you attempt to execute an action prior to this, it may fail, and `RubyAMI::Stream` will not help you recover or queue the action until the connection is `FullyBooted`; you must manage this timing yourself. That said, assuming you take care of this, you may invoke `RubyAMI::Stream#send_action` from anywhere in your code and it will return the response of the action.

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

Copyright (c) 2011-2016 Ben Langfeld, Jay Phillips. MIT licence (see LICENSE for details).
