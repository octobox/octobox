module Db
  class Postgres

    def fetch_label_repo_mapping(label_github_ids)
      label_repo_sql = <<-SQL.gsub("\n", ' ').squish
        SELECT DISTINCT ON (labels.github_id) labels.github_id, labels.id, repositories.id AS repository_id
        FROM
          labels
        INNER JOIN subjects
          ON subjects.id = labels.subject_id
        INNER JOIN repositories
          ON repositories.full_name = subjects.repository_full_name
        WHERE
          labels.repository_id is NULL
          AND
          labels.github_id IN (#{label_github_ids})
      SQL
      ActiveRecord::Base.connection.execute(label_repo_sql)
    end

    def fetch_unique_labels
      sql = <<-SQL.gsub("\n", ' ').squish
        SELECT id, github_id FROM (
          SELECT labels.id, labels.github_id, rank() over (
            partition BY labels.github_id ORDER BY labels.created_at
          )
          AS l FROM labels
        ) AS temp where l = 1 ORDER by id
      SQL

      ActiveRecord::Base.connection.execute(sql)
    end

    def import_labels(updated_labels, columns)
      Label.import updated_labels, on_duplicate_key_update: {
        conflict_target: [:id], columns: columns
      }
    end

    def fetch_existing_labels_on_repo(repository_id)
      sql = <<-SQL.gsub("\n", ' ').squish
        SELECT id, github_id FROM (
          SELECT labels.id, labels.github_id, rank() over (
            partition BY labels.github_id ORDER BY labels.created_at
          )
          AS l FROM labels where repository_id = #{repository_id}
        ) AS temp where l = 1 ORDER by id;
      SQL

      Label.find_by_sql(sql).pluck(:id, :github_id)
    end

  end
end