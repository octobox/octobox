# frozen_string_literal: true

class SyncInstallationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(payload)
    app_installation = AppInstallation.create({
      github_id: payload['installation']['id'],
      app_id: payload['installation']['app_id'],
      account_login: payload['installation']['account']['login'],
      account_id: payload['installation']['account']['id'],
      account_type: payload['installation']['account']['type'],
      target_type: payload['installation']['target_type'],
      target_id: payload['installation']['target_id'],
      permission_pull_requests: payload['installation']['permissions']['pull_requests'],
      permission_issues: payload['installation']['permissions']['issues'],
      permission_statuses: payload['installation']['permissions']['statuses']
    })

    app_installation.add_repositories(payload['repositories'])
  end
end
