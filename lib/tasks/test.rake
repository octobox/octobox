namespace :test do
  desc 'Run javascript tests'
  task javascript: :environment do
    Rake::Task['teaspoon'].invoke
  end
end
