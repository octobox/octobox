class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :github_id
      t.integer :repository_id
      t.string :repository_full_name
      t.string :subject_title
      t.string :subject_url
      t.string :subject_type
      t.string :reason
      t.boolean :unread
      t.string :last_read_at
      t.string :url
      t.boolean :archived, default: false

      t.timestamps
    end
  end
end
