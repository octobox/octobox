class ChangeGithubAccountIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :app_installations, :app_id, :bigint
    change_column :app_installations, :account_id, :bigint
    change_column :app_installations, :target_id, :bigint
    change_column :subscription_plans, :github_id, :bigint
    change_column :subscription_purchases, :account_id, :bigint
  end

  def down
    change_column :app_installations, :app_id, :integer
    change_column :app_installations, :account_id, :integer
    change_column :app_installations, :target_id, :integer
    change_column :subscription_plans, :github_id, :integer
    change_column :subscription_purchases, :account_id, :integer
  end
end
