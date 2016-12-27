class DropUniqueIndexOnGithubId < ActiveRecord::Migration[5.0]
  def change
    remove_index :notifications, :github_id
    add_index :notifications, [:user_id, :github_id], unique: true
  end
end
