class CreateRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.string :full_name, null: false, index: {unique: true}
      t.integer :github_id
      t.boolean :private
      t.string :owner
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
