class CreateRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.integer :github_id
      t.integer :app_installation_id
      t.string :full_name
      t.string :owner
      t.boolean :private

      t.timestamps
    end
  end
end
