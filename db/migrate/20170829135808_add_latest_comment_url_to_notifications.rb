class AddLatestCommentUrlToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :latest_comment_url, :string
  end
end
