# encoding: utf-8

require 'rubygems'
require 'bundler'
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
	gem.name = "robustserver"
	gem.summary = %Q{Robust Server}
	gem.description = %Q{Protects your Server against SIGS and  rescues all exceptions.}
	gem.email = "Denis.Knauf@gmail.com"
	gem.homepage = "http://github.com/DenisKnauf/robustserver"
	gem.authors = ["Denis Knauf"]
	gem.files = %w[AUTHORS README.md VERSION lib/**/*.rb test/**/*.rb]
	gem.require_paths = %w[lib]
	# dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

=begin
require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end
=end

task :default => :test

require 'yard'
YARD::Rake::YardocTask.new
