class AddDisableConfirmationsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :disable_confirmations, :boolean, default: false
  end
end
