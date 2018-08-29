namespace :release do
  desc "Generate Changelog"
  task notes: :environment do
    Octobox::Changelog.new.generate
  end
end
