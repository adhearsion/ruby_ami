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
require 'timeout'
desc "Run benchmarks"
task :benchmark do
  begin
    Timeout.timeout(120) do
      glob = File.expand_path("../benchmarks/*.rb", __FILE__)
      Dir[glob].each { |benchmark| load benchmark }
    end
  rescue Exception, Timeout::Error => ex
    puts "ERROR: Couldn't complete benchmark: #{ex.class}: #{ex}"
    puts "  #{ex.backtrace.join("\n  ")}"

    exit 1 unless ENV['CI'] # Hax for running benchmarks on Travis
  end
end

require 'yard'
YARD::Rake::YardocTask.new
