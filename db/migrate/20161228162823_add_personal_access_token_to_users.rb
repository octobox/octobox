class AddPersonalAccessTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :personal_access_token, :string
  end
end
