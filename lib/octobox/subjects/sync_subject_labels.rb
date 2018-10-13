module Octobox
  module Subjects
    module SyncSubjectLabels
      extend ActiveSupport::Concern

      included do
        has_many :subject_labels, :dependent => :destroy
        has_many :labels, :through => :subject_labels
      end

      def sync_labels(remote_labels)
        # detach removed labels from subject
        detach_subject_labels_removed_on_remote(remote_labels.map{|l| l['id'] })

        existing_labels_on_repo = Db::Resolver.new.db.fetch_existing_labels_on_repo(repository.id)
        # filter out and create new labels added for the first time on a repository
        labels_to_be_added = remote_labels.reject { |l|
          existing_labels_on_repo.collect(&:last).include?(l['id'])
        }.map {
          |l| Label.new(github_id: l['id'], color: l['color'], name: l['name'], repository_id: repository.id)
        }
        # insert new labels in bulk
        if labels_to_be_added.present?
          Label.import labels_to_be_added, on_duplicate_key_ignore: true
        end
        # update name and color of existing labels
        update_existing_labels(
          remote_labels,
          existing_labels_on_repo.reject { |label| labels_to_be_added.collect(&:github_id).include?(label.first) }
        )
        # create subject label mapping for New Added Labels
        attach_label_to_subject(remote_labels.map{|l| l['id'] })
      end

      def update_existing_labels(remote_labels, labels_for_update)
        return if labels_for_update.blank?

        updated_labels = []
        remote_labels.each do |label|
          if matching_label = labels_for_update.select { |l| l.last == label['id'] }.try(:first)
            updated_labels << {id: matching_label.first, color: label['color'], name: label['name']}
          end
        end

        Db::Resolver.new.db.import_labels(updated_labels, [:color, :name])
      end

      def attach_label_to_subject(label_github_ids)
        return if label_github_ids.blank?

        subject_labels = Label.where('github_id in (?) and repository_id is NOT NULL', label_github_ids).ids
        subject_labels.map!{ |label_id| SubjectLabel.new(subject_id: self.id, label_id: label_id) }
        SubjectLabel.import subject_labels, on_duplicate_key_ignore: true
      end

      def detach_subject_labels_removed_on_remote(remote_label_ids)
        return if remote_label_ids.blank?

        # filter all the labels removed from subject on remote and destroy
        SubjectLabel.joins(:label).where(
          "subject_labels.subject_id = ? and labels.github_id not in (?)",
          self.id, remote_label_ids
        ).destroy_all
      end
    end
  end
end
