class AddRepositoryFullNameIndexToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_index :subjects, :repository_full_name
  end
end
