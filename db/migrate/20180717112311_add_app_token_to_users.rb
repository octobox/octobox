class AddAppTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :encrypted_app_token, :string
    add_column :users, :encrypted_app_token_iv, :string
  end
end
