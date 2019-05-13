namespace :opencollective do
	desc "Sync supporters"
  task sync_supporters: :environment do
    Octobox::OpenCollective.sync
  end
end
