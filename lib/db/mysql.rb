module Db
  class Mysql

    def fetch_label_repo_mapping(label_github_ids)
      Label.joins(:subject => :repository).
      where("labels.repository_id is NULL and labels.github_id IN (?)", label_github_ids).
      select("labels.github_id, labels.id, repositories.id AS repository_id")
    end

    def fetch_unique_labels
      Label.group("github_id").order("created_at ASC").select("id, github_id")
    end

    def import_labels(updated_labels, columns)
      Label.import updated_labels, on_duplicate_key_update: columns
    end

    def fetch_existing_labels_on_repo(repository_id)
      Label.where("repository_id = ? ", repository_id).group("github_id").
      order("created_at ASC").pluck(:id, :github_id)
    end

  end
end