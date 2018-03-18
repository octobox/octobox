class CreateLabels < ActiveRecord::Migration[5.1]
  def change
    create_table :labels do |t|
      t.string :name, index: true
      t.string :color
      t.belongs_to :subject, index: true, add_foreign_key: true

      t.timestamps
    end

    add_foreign_key :labels, :subjects, on_update: :cascade, on_delete: :cascade
  end
end
