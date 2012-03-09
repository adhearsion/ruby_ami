require 'bundler/gem_tasks'

require 'rspec/core'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = '--color'
end

require 'cucumber'
require 'cucumber/rake/task'
require 'ci/reporter/rake/cucumber'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = %w{--tags ~@jruby} unless defined?(JRUBY_VERSION)
end

Cucumber::Rake::Task.new(:wip) do |t|
  t.cucumber_opts = %w{-p wip}
end

task :default => [:ragel, :spec, :features]
task :ci => [:ragel, 'ci:setup:rspec', :spec, 'ci:setup:cucumber', :features]

require 'yard'
YARD::Rake::YardocTask.new

desc "Check Ragel version"
task :check_ragel_version do
  ragel_version_match = `ragel --version`.match /(\d)\.(\d)+/
  abort "Could not get Ragel version! Is it installed? You must have at least version 6.3" unless ragel_version_match
  big, small = ragel_version_match.captures.map &:to_i
  if big < 6 || (big == 6 && small < 3)
    abort "Please upgrade Ragel! You're on version #{ragel_version_match[0]} and must be on 6.3 or later"
  end
  if (big == 6 && small < 7)
    puts "WARNING: A change to Ruby since 1.9 affects the Ragel generated code."
    puts "WARNING: You MUST be using Ragel version 6.7 or have patched it using"
    puts "WARNING: the patch found at:"
    puts "WARNING: http://www.mail-archive.com/ragel-users@complang.org/msg00440.html"
  end
end

desc "Used to regenerate the AMI source code files. Note: requires Ragel 6.3 or later be installed on your system"
task :ragel => :check_ragel_version do
  run_ragel '-n -R'
end

desc "Generates a GraphVis document showing the Ragel state machine"
task :visualize_ragel => :check_ragel_version do
  run_ragel '-V', 'dot'
end

def run_ragel(options = nil, extension = 'rb')
  ragel_file = 'lib/ruby_ami/lexer.rl.rb'
  base_file = ragel_file.sub ".rl.rb", ""
  command = ["ragel", options, "#{ragel_file} -o #{base_file}.#{extension} 2>&1"].compact.join ' '
  puts "Running command '#{command}'"
  puts `#{command}`
  raise "Failed generating code from Ragel file #{ragel_file}" if $?.to_i.nonzero?
end
