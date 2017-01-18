namespace :octobox do
  desc "Get overall stats for application"
  task stats: :environment do
    users         = "| Users: #{User.count}"
    notifications = "| Notifications: #{Notification.count}"

    active_user_count = User.select(&:last_synced_at).select{|u| u.last_synced_at > 1.day.ago}.count
    active_users      = "| Users recently active: #{active_user_count}"

    length = [notifications, users, active_users].map(&:length).max
    border_top_and_bottom = "+#{'-' * length}+"

    puts border_top_and_bottom
    puts "#{users.ljust(length)} |"
    puts "#{active_users.ljust(length)} |"
    puts "#{notifications.ljust(length)} |"
    puts border_top_and_bottom
  end
end
