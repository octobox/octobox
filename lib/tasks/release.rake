namespace :release do
  desc "Sync Notifications"
  task notes: :environment do
    Octobox::Changelog.new.generate
  end
end
