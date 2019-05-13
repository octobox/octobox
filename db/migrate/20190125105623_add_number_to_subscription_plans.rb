class AddNumberToSubscriptionPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :subscription_plans, :number, :integer
  end
end
