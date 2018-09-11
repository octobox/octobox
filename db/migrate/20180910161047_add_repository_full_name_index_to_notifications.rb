class AddRepositoryFullNameIndexToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_index :notifications, :repository_full_name
  end
end
