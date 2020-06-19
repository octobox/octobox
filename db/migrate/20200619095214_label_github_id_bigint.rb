class LabelGithubIdBigint < ActiveRecord::Migration[6.0]
  def change
    change_column :labels, :github_id, :bigint
  end
end
