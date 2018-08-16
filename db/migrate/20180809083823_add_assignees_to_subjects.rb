class AddAssigneesToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :assignees, :string, default: '::'
  end
end
