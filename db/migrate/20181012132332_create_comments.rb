class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.integer :subject_id
      t.bigint :github_id
      t.string :author
      t.string :author_association
      t.text :body

      t.timestamps
    end
  end
end
