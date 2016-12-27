namespace :tasks do
  desc "Sync Notifications"
  task sync_notifications: :environment do
    User.find_each do |user|
      user.sync_notifications
    end
  end
end
