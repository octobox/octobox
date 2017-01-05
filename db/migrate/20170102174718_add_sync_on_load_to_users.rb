class AddSyncOnLoadToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :sync_on_load, :boolean, null: false, default: false
  end
end
