class AddCommentsCountToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :comment_count, :integer
  end
end
