require 'benchmark'

namespace :benchmark do
  desc 'Benchmark syncing notifications'
  task sync: :environment do
    user = User.first
    Notification.delete_all
    Subject.delete_all
    user.last_synced_at = nil
    time = Benchmark.measure do
      user.sync_notifications
      user.sync_notifications
    end
    puts time
  end
end
