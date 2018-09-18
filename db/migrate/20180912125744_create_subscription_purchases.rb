class CreateSubscriptionPurchases < ActiveRecord::Migration[5.2]
  def change
    create_table :subscription_purchases do |t|
      t.integer :subscription_plan_id
      t.integer :account_id
      t.string :billing_cycle
      t.integer :unit_count
      t.boolean :on_free_trial
      t.datetime :free_trial_ends_on
      t.datetime :next_billing_date

      t.timestamps
    end
  end
end
