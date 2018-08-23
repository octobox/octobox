class AddGithubIdToSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :subjects, :github_id, :integer
  end
end
