class AddAppInstallationIdToRepositories < ActiveRecord::Migration[5.2]
  def change
    add_column :repositories, :app_installation_id, :integer
  end
end
