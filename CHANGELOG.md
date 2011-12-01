# develop

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
