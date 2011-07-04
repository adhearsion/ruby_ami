# RubyAMI
RubyAMI is an AMI client library in Ruby and based on EventMachine with the sole purpose of providing an connection to the Asterisk Manager Interface. RubyAMI does not provide any features beyond connection management and protocol parsing. Actions are sent over the wire, and responses come back via callbacks. It's up to you to match these up into something useful. In this regard, RubyAMI is very similar to [Blather](https://github.com/sprsquish/blather) for XMPP or Punchblock, the Ruby 3PCC library. In fact, Punchblock uses RubyAMI under the covers for its Asterisk implementation.

## Installation
    gem install ruby_ami

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
