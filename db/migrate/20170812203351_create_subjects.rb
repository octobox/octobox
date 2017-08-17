class CreateSubjects < ActiveRecord::Migration[5.1]
  def change
    create_table :subjects do |t|
      t.string :url, index: true
      t.string :state
      t.string :author

      t.timestamps
    end
  end
end
