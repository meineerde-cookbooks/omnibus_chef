# encoding: utf-8

require 'rubocop/rake_task'
Rubocop::RakeTask.new(:rubocop)

require 'foodcritic'
FoodCritic::Rake::LintTask.new

task :default => [:rubocop, :foodcritic]
