# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

Rake::Task['assets:precompile'].enhance ['api_docs:generate']

task 'test:skip_visuals' => 'test:prepare' do
  ['channels', 'controllers', 'integration', 'helpers', 'lib', 'models',
   'services', 'validators', 'workers'].each do |name|
    $: << 'test'
    Rails::TestUnit::Runner.rake_run(["test/#{name}"])
  end
end

task 'test:visuals' => 'test:prepare' do
  $: << "test"
  Rails::TestUnit::Runner.rake_run(["test/visuals"])
end

task(:default).clear.enhance ['test:skip_visuals']

if %w[development test].include? Rails.env
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new

  task(:default).enhance %i[rubocop]
end
