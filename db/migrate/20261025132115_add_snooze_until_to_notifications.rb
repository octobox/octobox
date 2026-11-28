class AddSnoozeUntilToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :snooze_until, :datetime
    add_index :notifications, :snooze_until
  end
end
