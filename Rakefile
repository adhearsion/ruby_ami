require 'bundler/gem_tasks'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = '--color'
end

require 'cucumber'
require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = %w{--tags ~@jruby} unless defined?(JRUBY_VERSION)
end

Cucumber::Rake::Task.new(:wip) do |t|
  t.cucumber_opts = %w{-p wip}
end

task :default => [:spec, :features]

require 'yard'
YARD::Rake::YardocTask.new
