namespace :octobox do
  desc "Get overall stats for the application"
  task stats: :environment do
    users         = "| Users: #{User.count}"
    notifications = "| Notifications: #{Notification.count}"
    subjects      = "| Subjects: #{Subject.count}"

    active_user_count = User.where('last_synced_at > ?', 1.day.ago).count
    active_users      = "| Users active within the last 24 hours: #{active_user_count}"

    length = [notifications, users, active_users, subjects].map(&:length).max
    border_top_and_bottom = "+#{'-' * length}+"

    puts border_top_and_bottom
    puts "#{users.ljust(length)} |"
    puts "#{active_users.ljust(length)} |"
    puts "#{notifications.ljust(length)} |"
    puts "#{subjects.ljust(length)} |"
    puts border_top_and_bottom
  end
end
