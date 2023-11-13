class AddTitleToSubjects < ActiveRecord::Migration[6.1]
  def change
    add_column :subjects, :title, :string
  end
end
