# [develop](https://github.com/adhearsion/ruby_ami)
  * Enhancement: Replace Ragel parser with pure Ruby version, which is much more performant and simpler
  * Bugfix: Handle AGI 5xx responses

# [2.0.0](https://github.com/adhearsion/ruby_ami/compare/v1.3.3...v2.0.0) - [2013-04-15](https://rubygems.org/gems/ruby_ami/versions/2.0.0)
  * Major refactoring for simplification and performance
  * Actions are no longer synchronised on the wire since ActionID is now a reliable method of response/event association
  * Callbacks are no longer required. #send_action now simply blocks waiting for a response
  * Client still starts up two Streams, one for actions and one for events, but only for possible performance gains. It is possible to use Stream directly since it now does its own login and response association. Client is a very thin routing layer. It's encouraged that if you expect low traffic, you should use Stream directly. Client may be removed in v3.0.

# [1.3.4](https://github.com/adhearsion/ruby_ami/compare/v1.3.3...v1.3.4) - [2013-04-25](https://rubygems.org/gems/ruby_ami/versions/1.3.4)
  * Bugfix: Handle AGI 5xx responses

# [1.3.3](https://github.com/adhearsion/ruby_ami/compare/v1.3.2...v1.3.3) - [2013-04-09](https://rubygems.org/gems/ruby_ami/versions/1.3.3)
  * Bugfix: DBGet actions are now not terminated specially

# [1.3.2](https://github.com/adhearsion/ruby_ami/compare/v1.3.1...v1.3.2) - [2013-03-22](https://rubygems.org/gems/ruby_ami/versions/1.3.2)
  * CS: Avoid celluloid deprecation warnings

# [1.3.1](https://github.com/adhearsion/ruby_ami/compare/v1.3.0...v1.3.1) - [2013-03-20](https://rubygems.org/gems/ruby_ami/versions/1.3.1)
  * Bugfix: Add support for causal event types `confbridgelist` and `confbridgelistrooms`
  * Bugfix: Loosen celluloid dependency

# [1.3.0](https://github.com/adhearsion/ruby_ami/compare/v1.2.6...v1.3.0) - [2013-01-23](https://rubygems.org/gems/ruby_ami/versions/1.3.0)
  * Feature: Added timeout feature to client connection process. Currently does not work on Rubinius due to https://github.com/rubinius/rubinius/issues/2127

# [1.2.6](https://github.com/adhearsion/ruby_ami/compare/v1.2.5...v1.2.6) - [2012-12-26](https://rubygems.org/gems/ruby_ami/versions/1.2.6)
  * Bugfix: JRuby and rbx compatability

# [1.2.5](https://github.com/adhearsion/ruby_ami/compare/v1.2.4...v1.2.5) - [2012-10-24](https://rubygems.org/gems/ruby_ami/versions/1.2.5)
  * Bugfix: Log wire stuff at trace level

# [1.2.4](https://github.com/adhearsion/ruby_ami/compare/v1.2.3...v1.2.4) - [2012-10-13](https://rubygems.org/gems/ruby_ami/versions/1.2.4)
  * Bugfix: No longer suffer "invalid byte sequence" exceptions due to encoding mismatch. Thanks tboyko

# [1.2.3](https://github.com/adhearsion/ruby_ami/compare/v1.2.2...v1.2.3) - [2012-09-20](https://rubygems.org/gems/ruby_ami/versions/1.2.3)
  * Streams now inherit the client's logger

# [1.2.2](https://github.com/adhearsion/ruby_ami/compare/v1.2.1...v1.2.2) - [2012-09-05](https://rubygems.org/gems/ruby_ami/versions/1.2.2)
  * Streams now log syntax errors
  * Celluloid dependency updated

# [1.2.1](https://github.com/adhearsion/ruby_ami/compare/v1.2.0...v1.2.1) - [2012-07-19](https://rubygems.org/gems/ruby_ami/versions/1.2.1)
  * Use SecureRandom for UUIDs

# [1.2.0](https://github.com/adhearsion/ruby_ami/compare/v1.1.2...v1.2.0) - [2012-07-18](https://rubygems.org/gems/ruby_ami/versions/1.2.0)
  * Feature: Added parsers for (Async)AGI environment and result strings
  * Bugfix: Avoid a race condition in stream establishment and event receipt
  * Bugfix: If socket creation fails, log an appropriate error

# [1.1.2](https://github.com/adhearsion/ruby_ami/compare/v1.1.1...v1.1.2) - [2012-07-04](https://rubygems.org/gems/ruby_ami/versions/1.1.2)
  * Bugfix: Avoid recursive stream stopping

# [1.1.1](https://github.com/adhearsion/ruby_ami/compare/v1.1.0...v1.1.1) - [2012-06-25](https://rubygems.org/gems/ruby_ami/versions/1.1.1)
  * v1.1.0 re-released with fixed celluloid-io dependency

# [1.1.0](https://github.com/adhearsion/ruby_ami/compare/v1.0.1...v1.1.0) - [2012-06-16](https://rubygems.org/gems/ruby_ami/versions/1.1.0)
  * Change: Switch from EventMachine to Celluloid & CelluloidIO for better JRuby compatability and performance (action and events connections are now in separate threads)

# 1.0.1 - 2012-04-25
  * Bugfix: Actions which do not receive a response within 10s will allow further actions to be executed. Synchronous originate has a 60s timeout.

# 1.0.0 - 2012-03-09
  * Bugfix: Remove rcov
  * Bump to 1.0.0 since we're in active use

# 0.1.5 - 2011-12-22
  * Bugfix: Work consistently all all versions of Asterisk
    * Both 1.8 and 10
    * Login actions connection with events turned on (in order to get FullyBooted event)
    * Turn events off immediately after fully-booted
    * Pass FullyBooted events from the actions connection up to the event handler

# 0.1.4 - 2011-12-1
  * Bugfix: Actions connection should login with Events: System. This ensures that the FullyBooted event will come through on both connections.

# 0.1.3 - 2011-11-22
  * Bugfix: A client can now safely be shut down before it is started, and only performs actions on live streams.
  * Bugfix: RubyAMI::Error#inspect now shows an error's message and headers
  * Bugfix: Spec and JRuby fixes

# 0.1.2
  * Bugfix: Prevent stream connection status events being passed up to the consumer event handler
  * Bugfix: Corrected the README usage docs
  * Bugfix: Alias Logger#trace to Logger#debug if the consumer is using a simple logger without a trace level

# 0.1.1
  * Bugfix: Make countdownlatch and i18n runtime dependencies
  * Bugfig: Include the generated lexer file in the gem

# 0.1.0
  * Initial release
