class CreateAppInstallations < ActiveRecord::Migration[5.2]
  def change
    create_table :app_installations do |t|
      t.integer :github_id
      t.integer :app_id
      t.string :account_login
      t.integer :account_id
      t.string :account_type
      t.string :target_type
      t.integer :target_id
      t.string :permission_pull_requests
      t.string :permission_issues

      t.timestamps
    end
  end
end
