class AddSubjectAuthorToNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :subject_author, :string
  end
end
