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

  desc "Clean up duplicate subjects"
  task deduplicate_subjects: :environment do
    duplicate_subject_urls = Subject.select(:url).group(:url).having("count(*) > 1").pluck(:url)

    duplicate_subject_urls.each do |subject_url|
      duplicate_subjects = Subject.where(url: subject_url).order('updated_at DESC')
      duplicate_subjects[1..-1].each(&:destroy)
    end
  end

  desc "Update repository names"
  task update_repository_names: :environment do
    Repository.all.find_each do |repository|
      count = Notification.where(repository_id: repository.github_id).
                           where.not(repository_full_name: repository.full_name).
                           where.not(repository_owner_name: repository.owner).count
      if count > 0
        Notification.where(repository_id: repository.github_id).
                     where.not(repository_full_name: repository.full_name).
                     where.not(repository_owner_name: repository.owner).
                     update_all({
                      repository_full_name: repository.full_name,
                      repository_owner_name:  repository.owner
                    })
      end
    end
  end

  desc "Sync App Installations"
  task sync_installations: :environment do
    AppInstallation.sync_all
  end

  desc "cleanup unique-jobs cache"
  task cleanup_unique_jobs: :environment do
    Sidekiq.redis do |conn|
      conn.keys('uniquejobs:*').each do |key|
        conn.del(key)
      end
    end
  end
end
