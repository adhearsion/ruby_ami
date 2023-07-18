# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_ami/version"

Gem::Specification.new do |s|
  s.name        = "ruby_ami"
  s.version     = RubyAMI::VERSION
  s.authors     = ["Ben Langfeld", "Ben Klang"]
  s.email       = ["ben@langfeld.me", "bklang@mojolingo.com"]
  s.homepage    = ""
  s.summary     = %q{Futzing with AMI so you don't have to}
  s.description = %q{A Ruby client library for the Asterisk Management Interface built on Celluloid IO.}

  s.rubyforge_project = "ruby_ami"

  s.files         = `git ls-files`.split("\n") << 'lib/ruby_ami/lexer.rb'
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency %q<celluloid-io>, ["~> 0.13"]
  s.add_runtime_dependency %q<celluloid>, ["~> 0.15.2"]
  s.add_runtime_dependency %q<connection_pool>, ["~> 1.0"]

  s.add_development_dependency %q<bundler>, ["~> 1.0"]
  s.add_development_dependency %q<rspec>, ["~> 2.5"]
  s.add_development_dependency %q<cucumber>, [">= 0"]
  s.add_development_dependency %q<yard>, ["~> 0.6"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<guard-rspec>
  s.add_development_dependency %q<guard-shell>
  s.add_development_dependency %q<guard-cucumber>
  s.add_development_dependency %q<guard-rake>
  s.add_development_dependency %q<benchmark_suite>
end
