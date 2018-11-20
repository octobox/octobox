class AddGithubIdIndexToRepositories < ActiveRecord::Migration[5.2]
  def change
    add_index :repositories, :github_id
  end
end
