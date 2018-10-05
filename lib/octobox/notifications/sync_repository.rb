module Octobox
  module Notifications
    module SyncRepository
      extend ActiveSupport::Concern

      def update_repository(force = false)
        return unless Octobox.config.subjects_enabled?
        return if !force && repository != nil && updated_at - repository.updated_at < 2.seconds

        UpdateRepositoryWorker.perform_async_if_configured(self.id, force)
      end

      def update_repository_in_foreground(force = false)
        return unless Octobox.config.subjects_enabled?
        return if !force && repository != nil && updated_at - repository.updated_at < 2.seconds

        remote_repository = download_repository

        if remote_repository.nil?
          # if we can't access the repository, assume that it's private
          remote_repository = OpenStruct.new({
            full_name: repository_full_name,
            private: true,
            owner: {login: repository_owner_name}
          })
        end

        if repository
          repository.update_attributes({
            full_name: remote_repository.full_name,
            private: remote_repository.private,
            owner: remote_repository.owner[:login],
            github_id: remote_repository.id,
            last_synced_at: Time.current
          })
        else
          create_repository({
            full_name: remote_repository.full_name,
            private: remote_repository.private,
            owner: remote_repository.owner[:login],
            github_id: remote_repository.id,
            last_synced_at: Time.current
          })
        end
      end

      private

      def download_repository
        user.github_client.repository(repository_full_name)
      rescue Octokit::ClientError
        nil
      end

    end
  end
end
