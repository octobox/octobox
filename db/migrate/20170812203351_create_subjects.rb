class CreateSubjects < ActiveRecord::Migration[5.1]
  def change
    create_table :subjects do |t|
      t.string :url
      t.string :state
      t.string :author
    end
  end
end
