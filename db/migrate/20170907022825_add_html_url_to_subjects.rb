class AddHtmlUrlToSubjects < ActiveRecord::Migration[5.1]
  def change
    add_column :subjects, :html_url, :string
  end
end
