module LabelMappingUpdate
  module Mysql
    extend ActiveSupport::Concern

    module ClassMethods

      def fetch_label_repo_mapping(label_github_ids)
        Label.joins(:subject => :repository).where("labels.github_id IN (?)", label_github_ids).
        select("labels.github_id, labels.id, repositories.id AS repository_id")
      end

      def fetch_unique_labels_mysql
        Label.group("github_id").order("created_at ASC").select("id, github_id")
      end

      def import_labels(updated_labels)
        Label.import updated_labels, on_duplicate_key_update: [:repository_id]
      end

      def fetch_existing_labels_on_repo
        Label.where("repository_id = ? ", repository.id).group("github_id").
        order("created_at ASC").pluck(:id, :github_id)
      end

    end
  end
end