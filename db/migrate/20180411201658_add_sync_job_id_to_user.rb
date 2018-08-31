class AddSyncJobIdToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sync_job_id, :string
  end
end
