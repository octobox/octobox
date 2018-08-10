namespace :tasks do
  desc "Sync Notifications"
  task sync_notifications: :environment do
    User.find_each do |user|
      begin
        user.sync_notifications
      rescue Octokit::BadGateway, Octokit::ServerError, Octokit::ServiceUnavailable => e
        STDERR.puts "Failed to sync notifications for #{user.github_login}\n#{e.class}\n#{e.message}"
      end
    end
  end

  desc "Sync subjects"
  task sync_subjects: :environment do
    Notification.subjectable.without_subject.find_each{|n| n.send(:update_subject) }
  end
end
