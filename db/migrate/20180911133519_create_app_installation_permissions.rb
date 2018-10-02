class CreateAppInstallationPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :app_installation_permissions do |t|
      t.integer :app_installation_id
      t.integer :user_id

      t.timestamps
    end
  end
end
