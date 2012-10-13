# [develop](https://github.com/adhearsion/ruby_ami)
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
