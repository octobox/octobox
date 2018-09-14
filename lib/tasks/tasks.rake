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
    Notification.subjectable.find_each{|n| n.update_subject(true); print '.' }
  end

  desc "Sync repositories"
  task sync_repos: :environment do
    Notification.find_each{|n| n.update_repository(true); print '.' }
  end

  desc "Clean up duplicate subjects"
  task deduplicate_subjects: :environment do
    duplicate_subject_urls = Subject.select(:url).group(:url).having("count(*) > 1").pluck(:url)

    duplicate_subject_urls.each do |subject_url|
      duplicate_subjects = Subject.where(url: subject_url).order('updated_at DESC')
      duplicate_subjects[1..-1].each(&:destroy)
    end
  end
end
