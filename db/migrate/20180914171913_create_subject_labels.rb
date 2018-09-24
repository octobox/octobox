class CreateSubjectLabels < ActiveRecord::Migration[5.2]
  def self.up
    create_table :subject_labels do |t|
      t.references :label
      t.references :subject

      t.timestamps
    end
  end

  def self.down
    drop_table :subject_labels
  end
end
