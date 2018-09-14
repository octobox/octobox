class AddLockedToSubject < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :locked, :boolean
  end
end
