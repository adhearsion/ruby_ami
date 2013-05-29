guard 'rspec', :cli => '--format documentation' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/" }
end

guard 'cucumber', cli: '--no-profile --color --format progress --strict --tags ~@wip' do
  watch("lib/ruby_ami/lexer.rb")                        { 'features' }
  watch(%r{^features/.+\.feature$})
  watch(%r{^features/support/.+$})                      { 'features' }
  watch(%r{^features/step_definitions/(.+)_steps\.rb$}) { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'features' }
end

guard 'rake', task: 'benchmark' do
  watch("lib/ruby_ami/lexer.rb")
  watch(/benchmarks\/*/)
end
