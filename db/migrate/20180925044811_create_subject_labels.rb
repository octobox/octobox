class CreateSubjectLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :subject_labels do |t|
      t.references :label
      t.references :subject
      t.timestamps
    end
    add_index :subject_labels, [:subject_id, :label_id], :unique => true
  end
end
