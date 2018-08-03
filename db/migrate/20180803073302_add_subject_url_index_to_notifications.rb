class AddSubjectUrlIndexToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_index :notifications, :subject_url
  end
end
