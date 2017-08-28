class AllowNullForLastSyncedAtInUsers < ActiveRecord::Migration[5.0]
  def change
    change_column_null :users, :refresh_interval, true
  end
end
