class AddGithubIdToLabels < ActiveRecord::Migration[5.1]
  def change
    add_column :labels, :github_id, :integer
  end
end
