class AddAppTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :app_token, :string
  end
end
