class AddDisplayCommentsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :display_comments, :boolean, :default => false
  end
end
