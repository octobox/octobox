class AddOcTransactionidToSubscriptionPurchases < ActiveRecord::Migration[5.2]
  def change
    add_column :subscription_purchases, :oc_transactionid, :integer
  end
end
