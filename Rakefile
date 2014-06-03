$:.unshift File.expand_path('../lib', __FILE__)
require 'offsite_payments/version'

begin
  require 'bundler'
  Bundler.setup
rescue LoadError => e
  puts "Error loading bundler (#{e.message}): \"gem install bundler\" for bundler support."
  require 'rubygems'
end

require 'rake'
require 'rake/testtask'

task :gem => :build
task :build do
  raise "Please set a private key to sign the gem" unless ENV['GEM_PRIVATE_KEY']
  system "gem build activemerchant.gemspec"
end

task :install => :build do
  system "gem install activemerchant-#{ActiveMerchant::VERSION}.gem"
end

task :release => :build do
  system "git tag -a v#{ActiveMerchant::VERSION} -m 'Tagging #{ActiveMerchant::VERSION}'"
  system "git push --tags"
  system "gem push activemerchant-#{ActiveMerchant::VERSION}.gem"
  system "rm activemerchant-#{ActiveMerchant::VERSION}.gem"
end

desc "Run the unit test suite"
task :default => 'test:units'
task :test => 'test:units'

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.pattern = 'test/unit/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.libs << 'test'
    t.verbose = true
  end

  Rake::TestTask.new(:remote) do |t|
    t.pattern = 'test/remote/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.libs << 'test'
    t.verbose = true
  end
end
