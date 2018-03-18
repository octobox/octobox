class ChangeSubjectTitleFromStringToText < ActiveRecord::Migration[5.1]
  def up
    change_column :notifications, :subject_title, :text
  end

  def down
    change_column :notifications, :subject_title, :string
  end
end
