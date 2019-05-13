# frozen_string_literal: true

class SyncInstallationRepositoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_repos, unique: :until_and_while_executing

  def perform(payload)
    app_installation = AppInstallation.find_by_github_id(payload['installation']['id'])
    return unless app_installation.present?

    app_installation.add_repositories(payload['repositories_added'])
    app_installation.remove_repositories(payload['repositories_removed'])
  end
end
