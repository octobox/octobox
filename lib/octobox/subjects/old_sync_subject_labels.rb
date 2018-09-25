module Octobox
  module Subjects
    module OldSyncSubjectLabels
      extend ActiveSupport::Concern

      included do
        has_many :labels, dependent: :delete_all
      end

      def sync_labels(remote_labels)
        existing_labels = labels.to_a
        remote_labels.each do |l|
          label = labels.find_by_github_id(l['id'])
          if label.nil?
            labels.create({
              github_id: l['id'],
              color: l['color'],
              name: l['name'],
            })
          else
            label.github_id = l['id'] # smoothly migrate legacy labels
            label.color = l['color']
            label.name = l['name']
            label.save if label.changed?
          end
        end

        remote_label_ids = remote_labels.map{|l| l['id'] }
        deleted_labels = existing_labels.reject{|l| remote_label_ids.include?(l.github_id) }
        deleted_labels.each(&:destroy)
      end

    end
  end
end
