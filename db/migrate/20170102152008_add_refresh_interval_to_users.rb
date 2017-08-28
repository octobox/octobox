class AddRefreshIntervalToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :refresh_interval, :integer, null: false, default: 0
  end
end
