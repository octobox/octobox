class AddAssigneesToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :assignees, :string, array: true, default: []
  end
end
