# frozen_string_literal: true

class SyncInstallationRepositoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(payload)
    app_installation = AppInstallation.find_by_github_id(payload['installation']['id'])
    return unless app_installation.present?
    payload['repositories_added'].each do |remote_repository|
      repository = app_installation.repositories.find_or_create_by(github_id: remote_repository['id'])

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

    payload['repositories_removed'].each do |remote_repository|
      repository = app_installation.repositories.find_by_github_id(remote_repository['id'])
      next unless repository.present?
      repository.subjects.each(&:destroy)
      repository.destroy
    end
  end
end
