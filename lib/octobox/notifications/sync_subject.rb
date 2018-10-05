module Octobox
  module Notifications
    module SyncSubject
      extend ActiveSupport::Concern

      SUBJECT_TYPE_ISSUE_REQUEST = {
        Issue: 'Issue',
        PullRequest: 'PullRequest'
      }
      SUBJECT_TYPE_COMMIT_RELEASE = ['Commit', 'Release'].freeze
      SUBJECT_STATE_MERGED = 'merged'.freeze
      SUBJECT_STATUS_PENDING = 'pending'.freeze

      def update_subject(force = false)
        return unless display_subject?
        return if !force && subject != nil && updated_at - subject.updated_at < 2.seconds

        UpdateSubjectWorker.perform_async_if_configured(self.id, force)
      end

      def update_subject_in_foreground(force = false)
        return unless display_subject?
        # skip syncing if the notification was updated around the same time as subject
        return if !force && subject != nil && updated_at - subject.updated_at < 2.seconds

        remote_subject = download_subject
        return unless remote_subject.present?

        if subject
          case subject_type
          when *SUBJECT_TYPE_ISSUE_REQUEST.values
            subject.repository_full_name = repository_full_name
            subject.assignees = ":#{Array(remote_subject.assignees.try(:map, &:login)).join(':')}:"
            subject.state = remote_subject.merged_at.present? ? SUBJECT_STATE_MERGED : remote_subject.state
            subject.sha = remote_subject.head&.sha
            subject.save(touch: false) if subject.changed?
          end
        else
          case subject_type
          when *SUBJECT_TYPE_ISSUE_REQUEST.values
            create_subject({
              repository_full_name: repository_full_name,
              github_id: remote_subject.id,
              state: remote_subject.merged_at.present? ? SUBJECT_STATE_MERGED : remote_subject.state,
              author: remote_subject.user.login,
              html_url: remote_subject.html_url,
              created_at: remote_subject.created_at,
              updated_at: remote_subject.updated_at,
              assignees: ":#{Array(remote_subject.assignees.try(:map, &:login)).join(':')}:",
              locked: remote_subject.locked,
              sha: remote_subject.head&.sha
            })
          when *SUBJECT_TYPE_COMMIT_RELEASE
            create_subject({
              repository_full_name: repository_full_name,
              github_id: remote_subject.id,
              author: remote_subject.author&.login,
              html_url: remote_subject.html_url,
              created_at: remote_subject.created_at,
              updated_at: remote_subject.updated_at,
              locked: remote_subject.locked
            })
          end
        end

        case subject_type
        when *SUBJECT_TYPE_ISSUE_REQUEST.values
          subject.update_labels(remote_subject.labels) if remote_subject.labels.present?
        end

        if subject_type == SUBJECT_TYPE_ISSUE_REQUEST[:PullRequest] && remote_subject.statuses_url.present?
          remote_status = download_status(remote_subject.statuses_url)
          if remote_status.present?
            subject.status = assign_status(remote_status)
            subject.save if subject.changed?
          end
        end
      end

      private

      def assign_status(remote_status)
        case remote_status.state
        when SUBJECT_STATUS_PENDING
          remote_status.statuses.present? ? remote_status.state : nil
        else
          remote_status.state
        end
      end

      def combined_status_url(status_url)
        "#{status_url}/status".gsub('statuses', 'commits')
      end

      def download_status(status_url)
        user.subject_client.get(
          combined_status_url(status_url)
        )
      rescue Octokit::ClientError
        nil
      end

      def download_subject
        user.subject_client.get(subject_url)

      # If permissions changed and the user hasn't accepted, we get a 401
      # We may receive a 403 Forbidden or a 403 Not Available
      # We may be rate limited and get a 403 as well
      # We may also get blocked by legal reasons (451)
      # Regardless of the reason, any client error should be rescued and warned so we don't
      # end up blocking other syncs
      rescue Octokit::ClientError => e
        Rails.logger.warn("\n\n\033[32m[#{Time.now}] WARNING -- #{e.message}\033[0m\n\n")
        nil
      end

    end
  end
end
