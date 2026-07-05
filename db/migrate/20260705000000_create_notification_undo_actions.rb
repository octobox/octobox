class CreateNotificationUndoActions < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_undo_actions do |t|
      t.references :user, null: false, index: true
      t.string :token, null: false
      t.string :action, null: false
      t.text :notification_states, null: false, limit: 16.megabytes
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :notification_undo_actions, :token, unique: true
    add_index :notification_undo_actions, :expires_at
  end
end
