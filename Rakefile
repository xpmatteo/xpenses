require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "src"
  t.pattern = "test/*_test.rb"
end

