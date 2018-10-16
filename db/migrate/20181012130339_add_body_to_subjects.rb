class AddBodyToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :body, :text
  end
end
