class AddRepositoryOwnerNameToNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :repository_owner_name, :string, default: ''
  end
end
