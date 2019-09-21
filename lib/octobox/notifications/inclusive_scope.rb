module Octobox
  module Notifications
    module InclusiveScope
      extend ActiveSupport::Concern

      included do
        scope :muted,    -> { where("muted_at IS NOT NULL") }
        scope :inbox,    -> { where.not(archived: true) }
        scope :archived, ->(value = true) { where(archived: value) }
        scope :newest,   -> { order('notifications.updated_at DESC') }
        scope :starred,  ->(value = true)  { where(starred: value) }
        scope :type,     ->(subject_type)  { where(subject_type: subject_type) }
        scope :reason,   ->(reason)        { where(reason: reason) }
        scope :unread,   ->(unread)        { where(unread: unread) }
        scope :status,   ->(status)        { joins(:subject).where(subjects: { status: status }) }
        scope :draft,    ->(draft = true) { joins(:subject).where(subjects: { draft: draft }) }
        scope :unassigned, -> { joins(:subject).where("subjects.assignees = '::'") }
        scope :locked,     -> { joins(:subject).where(subjects: { locked: true }) }
        scope :subjectable,-> { where(subject_type: Notification::SUBJECTABLE_TYPES) }
        scope :commentable,-> { where(subject_type: Notification::SUBJECT_TYPE_COMMENTS) }
        scope :bot_author, ->(bot_author = true) {
          if bot_author
            joins(:subject).where('subjects.author LIKE ? OR subjects.author LIKE ?', '%[bot]', '%-bot')
          else
            joins(:subject).where.not('subjects.author LIKE ? OR subjects.author LIKE ?', '%[bot]', '%-bot')
          end
        }
        scope :labelable,  -> { where(subject_type: ['Issue', 'PullRequest']) }
        scope :is_private, ->(is_private = true) { joins(:repository).where('repositories.private = ?', is_private) }
        scope :unlabelled, -> { labelable.with_subject.left_outer_joins(:labels).where(labels: {id: nil})}
        scope :with_subject,-> { includes(:subject).where.not(subjects: { url: nil }) }

        scope :repo, lambda { |repo_names|
          repo_names = [repo_names] if repo_names.is_a?(String)
          where(
            repo_names.map { |repo_name| arel_table[:repository_full_name].matches(repo_name) }.reduce(:or)
          )
        }

        scope :owner, ->(owner_names)   {
          owner_names = [owner_names] if owner_names.is_a?(String)
          where(
            owner_names.map { |owner_name| arel_table[:repository_owner_name].matches(owner_name) }.reduce(:or)
          )
        }

        scope :author, ->(author_names)  {
          author_names = [author_names] if author_names.is_a?(String)
          joins(:subject).where(
            author_names.map { |author_name| Subject.arel_table[:author].matches(author_name) }.reduce(:or)
          )
        }

        scope :state, ->(states)  {
          states = [states] if states.is_a?(String)
          joins(:subject).where(
            states.map { |state| Subject.arel_table[:state].matches(state) }.reduce(:or)
          )
        }

        scope :label, ->(label_names) {
          label_names = [label_names] if label_names.is_a?(String)

          joins(:labels).where(
            label_names.map { |label_name| Label.arel_table[:name].matches(label_name) }.reduce(:or)
          )

        }

        scope :assigned, ->(assignees) {
          assignees = [assignees] if assignees.is_a?(String)
          joins(:subject).where(
            assignees.map { |assignee| Subject.arel_table[:assignees].matches("%:#{assignee}:%") }.reduce(:or)
          )
        }

        scope :review_requested, ->(reviewers) {
          joins(:subject).where(
            Array(reviewers).map { |reviewer| Subject.arel_table[:requested_reviewers].matches("%:#{reviewer}:%") }.reduce(:or)
          )
        }

        scope :team_review_requested, ->(fully_qualified_teams) {
          teams = Array(fully_qualified_teams).map do |team_identifier|
            org, name = team_identifier.split("/")
            { organization: org, name: name }
          end

          joins(:subject).where(
            teams.map { |team|
              arel_table[:repository_owner_name].matches(team[:organization])
                .and(Subject.arel_table[:requested_teams].matches("%:#{team[:name]}:%"))
            }.reduce(:or)
          )
        }
      end
    end
  end
end
