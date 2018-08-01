class CreateUserSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :user_settings do |t|
      t.boolean :new_tab, default: true, null: false
      t.references :user, null: false, index: { unique: true }

      t.timestamps
    end

    add_foreign_key :user_settings, :users, on_delete: :cascade
  end
end
