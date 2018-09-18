class CreateSubscriptionPlans < ActiveRecord::Migration[5.2]
  def change
    create_table :subscription_plans do |t|
      t.integer :github_id
      t.string :name
      t.string :description
      t.integer :monthly_price_in_cents
      t.integer :yearly_price_in_cents
      t.string :price_model
      t.boolean :has_free_trial
      t.string :unit_name

      t.timestamps
    end
  end
end
