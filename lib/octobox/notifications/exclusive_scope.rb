module Octobox
  module Notifications
    module ExclusiveScope
      extend ActiveSupport::Concern

      included do
        scope :unmuted,        -> { where("muted_at IS NULL") }
        scope :exclude_type,   ->(subject_type) { where.not(subject_type: subject_type) }
        scope :exclude_status, ->(status)       { joins(:subject).where("subjects.status is NULL or subjects.status != ?", status) }
        scope :exclude_reason, ->(reason)       { where.not(reason: reason) }
        scope :not_locked,     -> { joins(:subject).where(subjects: { locked: false }) }
        scope :without_subject, -> { includes(:subject).where(subjects: { url: nil }) }
        scope :exclude_github_login, ->(github_login) { joins(:user).where.not(users: { github_login: github_login }) }

        scope :exclude_repo, lambda { |repo_names|
          repo_names = [repo_names] if repo_names.is_a?(String)
          where.not(
            repo_names.map { |repo_name| arel_table[:repository_full_name].matches(repo_name) }.reduce(:or)
          )
        }

        scope :exclude_owner, ->(owner_names)   {
          owner_names = [owner_names] if owner_names.is_a?(String)
          where.not(
            owner_names.map { |owner_name| arel_table[:repository_owner_name].matches(owner_name) }.reduce(:or)
          )
        }

        scope :exclude_author, ->(author_names)  {
          author_names = [author_names] if author_names.is_a?(String)
          joins(:subject).where.not(
            author_names.map { |author_name| Subject.arel_table[:author].matches(author_name) }.reduce(:or)
          )
        }

        scope :exclude_state, ->(states)  {
          states = [states] if states.is_a?(String)
          joins(:subject).where.not(
            states.map { |state| Subject.arel_table[:state].matches(state) }.reduce(:or)
          )
        }

        scope :exclude_label, ->(label_names) {
          label_names = [label_names] if label_names.is_a?(String)
          joins(:labels).where.not(
            label_names.map { |label_name| Label.arel_table[:name].matches(label_name) }.reduce(:or)
          )
        }

        scope :exclude_assigned, ->(assignees) {
          assignees = [assignees] if assignees.is_a?(String)
          joins(:subject).where.not(
            assignees.map { |assignee| Subject.arel_table[:assignees].matches("%:#{assignee}:%") }.reduce(:or)
          )
        }

      end
    end
  end
end
