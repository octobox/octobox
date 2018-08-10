class AddEncryptedAccessTokenToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :encrypted_access_token, :string
    add_column :users, :encrypted_access_token_iv, :string
    remove_column :users, :access_token, :string

    add_column :users, :encrypted_personal_access_token, :string
    add_column :users, :encrypted_personal_access_token_iv, :string
    remove_column :users, :personal_access_token, :string
  end
end
