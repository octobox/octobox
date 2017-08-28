# frozen_string_literal: true
class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.integer :github_id,    null: false
      t.string  :access_token, null: false
      t.string  :github_login, null: false

      t.timestamps
    end

    add_index :users, :github_id,    unique: true
    add_index :users, :access_token, unique: true
  end
end
