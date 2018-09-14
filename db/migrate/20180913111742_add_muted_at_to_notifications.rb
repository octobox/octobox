class AddMutedAtToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :muted_at, :datetime, null: true
    add_index :notifications, :muted_at
  end
end
