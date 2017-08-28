class AddStarredToNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :starred, :boolean, default: false
  end
end
