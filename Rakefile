# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rubocop/rake_task'
require_relative 'config/application'

Rails.application.load_tasks

RuboCop::RakeTask.new

Rake::Task['assets:precompile'].enhance ['api_docs:generate']

task 'test:skip_visuals' => 'test:prepare' do
  ["models", "helpers", "controllers", "integration", "workers"].each do |name|
    $: << "test"
    Rails::TestUnit::Runner.rake_run(["test/#{name}"])
  end
end

task 'test:visuals' => 'test:prepare' do
  $: << "test"
  Rails::TestUnit::Runner.rake_run(["test/visuals"])
end

task(:default).clear.enhance ['test:skip_visuals', 'rubocop']
