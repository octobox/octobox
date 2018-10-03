class AddStatusToSubjects < ActiveRecord::Migration[5.2]
  def change
  	add_column :subjects, :sha, :string, index: true
    add_column :subjects, :status, :string
  end
end
