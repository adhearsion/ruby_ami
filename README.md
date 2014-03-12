# RubyAMI [![Build Status](https://secure.travis-ci.org/adhearsion/ruby_ami.png?branch=master)](http://travis-ci.org/adhearsion/ruby_ami)
RubyAMI is an AMI client library in Ruby and based on EventMachine with the sole purpose of providing a connection to the Asterisk Manager Interface. RubyAMI does not provide any features beyond connection management and protocol parsing. Actions are sent over the wire, and responses are returned. Events are passed to a callback you define. It's up to you to match these up into something useful. In this regard, RubyAMI is very similar to [Blather](https://github.com/sprsquish/blather) for XMPP or [Punchblock](https://github.com/adhearsion/punchblock), the Ruby 3PCC library. In fact, Punchblock uses RubyAMI under the covers for its Asterisk implementation, including an implementation of AsyncAGI.

NB: If you're looking to develop an application on Asterisk, you should take a look at the [Adhearsion](http://adhearsion.com) framework first. This library is much lower level.

## Installation
    gem install ruby_ami

## Usage
```ruby
require 'ruby_ami'

stream = RubyAMI::Stream.new '127.0.0.1', 5038, 'manager', 'password',
                              ->(e) { handle_event e },
                              Logger.new(STDOUT), 10

def handle_event(event)
  case event.name
  when 'FullyBooted'
    stream.async.send_action 'Originate', 'Channel' => 'SIP/foo'
  end
end

stream.start

Celluloid::Actor.join stream
```

RubyAMI also has a class called `RubyAMI::Client` which used to be the main usage method. The purpose of this class was to tie together two AMI connections and separate events and action execution between the two in order to avoid some issues present in Asterisk < 1.8 with regards to separating overlapping events and executing multiple actions simultaneously. These issues are no longer present, and so **`RubyAMI::Client` is now deprecated and will be removed in RubyAMI 3.0**.

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

Copyright (c) 2013 Ben Langfeld, Jay Phillips. MIT licence (see LICENSE for details).
