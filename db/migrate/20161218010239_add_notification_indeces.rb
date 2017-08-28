class AddNotificationIndeces < ActiveRecord::Migration[5.0]
  def change
    add_index :notifications, [:user_id, :archived, :updated_at]
    add_index :notifications, :github_id, unique: true
  end
end
