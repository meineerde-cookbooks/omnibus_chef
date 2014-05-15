# encoding: utf-8

require 'rubocop/rake_task'
Rubocop::RakeTask.new(:rubocop)

require 'foodcritic'
FoodCritic::Rake::LintTask.new do |t|
  t.options = {
    :fail_tags => ['any'],
    # We allow FC024 as the platforms in attributes/default.rb are rather
    # complex
    :tags => ['~FC024']
  }
end

task :default => [:rubocop, :foodcritic]
