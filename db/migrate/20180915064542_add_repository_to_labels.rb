class AddRepositoryToLabels < ActiveRecord::Migration[5.2]
  def change
    add_reference :labels, :repository, foreign_key: true, index: true
  end
end
