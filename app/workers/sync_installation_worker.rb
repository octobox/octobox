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
      permission_issues: payload['installation']['permissions']['issues']
    })

    payload['repositories'].each do |remote_repository|
      repository = Repository.find_or_create_by(github_id: remote_repository['id'])

      repository.update_attributes({
        full_name: remote_repository['full_name'],
        private: remote_repository['private'],
        owner: remote_repository['full_name'].split('/').first,
        github_id: remote_repository['id'],
        last_synced_at: Time.current,
        app_installation_id: app_installation['id']
      })

      repository.notifications.find_each{|n| n.send :update_subject, true }
    end
  end
end
