class AddPermissionCommitStatusToAppInstallations < ActiveRecord::Migration[5.2]
  def change
    add_column :app_installations, :permission_statuses, :string
  end
end
