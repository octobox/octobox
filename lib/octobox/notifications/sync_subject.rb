module Octobox
  module Notifications
    module SyncSubject
      extend ActiveSupport::Concern

      SUBJECT_TYPE_ISSUE_REQUEST = ['Issue', 'PullRequest'].freeze
      SUBJECT_TYPE_COMMIT_RELEASE = ['Commit', 'Release'].freeze
      SUBJECT_TYPE_COMMENTS = SUBJECT_TYPE_ISSUE_REQUEST + ['Commit']

      def update_subject(force = false)
        return unless download_subject?
        return if !force && subject != nil && updated_at - subject.updated_at < 2.seconds

        UpdateSubjectWorker.perform_async_if_configured(self.id, force)
      end

      def update_subject_in_foreground(force = false)
        return unless download_subject?
        # skip syncing if the notification was updated around the same time as subject
        return if !force && subject != nil && updated_at - subject.updated_at < 2.seconds

        remote_subject = download_subject
        return unless remote_subject.present?

        Subject.sync(remote_subject.to_h.as_json)
      end

      def github_client
        if user.personal_access_token_enabled?
          user.personal_access_token_client
        elsif app_installation.present?
          user.app_installation_client
        else
          user.access_token_client
        end
      end

      def download_subject?
        @download_subject ||= user.present? && subjectable? && github_client && (Octobox.fetch_subject? || github_app_installed? || download_public_subjects?)
      end

      def download_public_subjects?
        return false if private?
        if Octobox.config.public_subject_rollout
          updated_at > Octobox.config.public_subject_rollout
        else
          return true
        end
      end

      private

      def download_subject
        github_client.get(subject_url)

      # If permissions changed and the user hasn't accepted, we get a 401
      # We may receive a 403 Forbidden or a 403 Not Available
      # We may be rate limited and get a 403 as well
      # We may also get blocked by legal reasons (451)
      # Regardless of the reason, any client error should be rescued and warned so we don't
      # end up blocking other syncs
      rescue Octokit::ClientError => e
        Rails.logger.warn("\n\n\033[32m[#{Time.current}] WARNING -- #{e.message}\033[0m\n\n")
        nil
      end
    end
  end
end
