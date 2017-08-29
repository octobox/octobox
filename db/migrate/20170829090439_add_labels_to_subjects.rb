class AddLabelsToSubjects < ActiveRecord::Migration[5.1]
  def change
    add_column :subjects, :labels, :string, array: true, default: []
  end
end
