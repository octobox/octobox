class ChangeSubjectGithubIdToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :subjects, :github_id, :bigint
    change_column :repositories, :github_id, :bigint
    change_column :users, :github_id, :bigint
    change_column :app_installations, :github_id, :bigint
  end

  def down
    change_column :subjects, :github_id, :integer
    change_column :repositories, :github_id, :integer
    change_column :users, :github_id, :integer
    change_column :app_installations, :github_id, :integer
  end
end
