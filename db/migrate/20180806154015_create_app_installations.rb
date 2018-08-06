class CreateAppInstallations < ActiveRecord::Migration[5.2]
  def change
    create_table :app_installations do |t|
      t.integer :github_id
      t.string :account_login
      t.integer :account_id
      t.jsonb :data

      t.timestamps
    end
  end
end
