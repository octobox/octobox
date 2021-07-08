class ChangeNotificationIdType < ActiveRecord::Migration[6.1]
  def change
    change_column :notifications, :github_id, :bigint
  end
end
