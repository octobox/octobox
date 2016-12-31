class AddFullTextSearchIndexes < ActiveRecord::Migration[5.0]
  def up
    execute "create index notifications_subject_title on notifications using gin(to_tsvector('english', subject_title))"
  end

  def down
    execute "drop index notifications_subject_title"
  end
end
