# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_ami/version"

Gem::Specification.new do |s|
  s.name        = "ruby_ami"
  s.version     = RubyAMI::VERSION
  s.authors     = ["Ben Langfeld"]
  s.email       = ["ben@langfeld.me"]
  s.homepage    = ""
  s.summary     = %q{Futzing with AMI so you don't have to}
  s.description = %q{A Ruby client library for the Asterisk Management Interface build on eventmachine.}

  s.rubyforge_project = "ruby_ami"

  s.files         = `git ls-files`.split("\n") << 'lib/ruby_ami/lexer.rb'
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency %q<activesupport>, [">= 3.0.9"]
  s.add_runtime_dependency %q<uuidtools>, [">= 0"]
  s.add_runtime_dependency %q<eventmachine>, [">= 0"]
  s.add_runtime_dependency %q<future-resource>, [">= 0"]
  s.add_runtime_dependency %q<girl_friday>, [">= 0"]
  s.add_runtime_dependency %q<countdownlatch>, [">= 1.0.0"]
  s.add_runtime_dependency %q<i18n>, [">= 0"]

  s.add_development_dependency %q<bundler>, ["~> 1.0.0"]
  s.add_development_dependency %q<rspec>, [">= 2.5.0"]
  s.add_development_dependency %q<cucumber>, [">= 0"]
  s.add_development_dependency %q<ci_reporter>, [">= 1.6.3"]
  s.add_development_dependency %q<yard>, ["~> 0.6.0"]
  s.add_development_dependency %q<rcov>, [">= 0"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<mocha>, [">= 0"]
  s.add_development_dependency %q<simplecov>, [">= 0"]
  s.add_development_dependency %q<simplecov-rcov>, [">= 0"]
  s.add_development_dependency %q<guard-rspec>
end
