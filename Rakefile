# encoding: utf-8

require 'rubygems'
require 'bundler'
require File.dirname(__FILE__) + "/lib/sqlite_wrapper"

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = '0.0.1'
  gem.name = "sqlite_wrapper"
  gem.homepage = "http://github.com/julik/sqlite_wrapper"
  gem.license = "Proprietary"
  gem.summary = %Q{Simple SQLite toolbelt}
  gem.description = %Q{Simple SQLite toolbelt}
  gem.email = "me@julik.nl"
  gem.authors = ["Julik Tarkhanov"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
