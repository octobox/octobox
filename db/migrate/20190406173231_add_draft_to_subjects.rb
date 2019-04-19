class AddDraftToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :draft, :boolean, default: false
  end
end
