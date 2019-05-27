class AddSnoozeUntilToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :snooze_until, :datetime
  end
end
