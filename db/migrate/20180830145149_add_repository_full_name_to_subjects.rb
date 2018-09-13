class AddRepositoryFullNameToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :repository_full_name, :string
  end
end
