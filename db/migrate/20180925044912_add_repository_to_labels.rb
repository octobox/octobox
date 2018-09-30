class AddRepositoryToLabels < ActiveRecord::Migration[5.2]
  def change
    add_reference :labels, :repository, foreign_key: true, index: true
    add_index :labels, :created_at
    add_index :labels, :github_id, unique: true
  end
end
