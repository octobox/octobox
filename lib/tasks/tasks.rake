namespace :tasks do
  desc "Sync Notifications"
  task sync_notifications: :environment do
    User.find_each do |user|
      begin
        user.sync_notifications
      rescue Octokit::BadGateway, Octokit::ServiceUnavailable => e
        STDERR.puts "Failed to sync notifications for #{user.github_login}\n#{e.class}\n#{e.message}"
      end
    end
  end
end
