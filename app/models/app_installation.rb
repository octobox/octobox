class AppInstallation < ApplicationRecord
  has_many :repositories, dependent: :destroy
  has_many :app_installation_permissions, dependent: :delete_all
  has_many :users, through: :app_installation_permissions
  has_one :subscription_purchase, foreign_key: :account_id, primary_key: :account_id, dependent: :destroy

  validates :github_id, presence: true, uniqueness: true
  validates :account_login, presence: true
  validates :account_id, presence: true

  def add_repositories(remote_repositories)
    remote_repositories.each do |remote_repository|
      repository = Repository.find_or_create_by(github_id: remote_repository['id'])

      repository.update({
        full_name: remote_repository['full_name'],
        private: remote_repository['private'],
        owner: remote_repository['full_name'].split('/').first,
        github_id: remote_repository['id'],
        last_synced_at: Time.current,
        app_installation_id: self.id
      })

      repository.sync_subjects
    end
  end

  def remove_repositories(remote_repositories)
    remote_repositories.each do |remote_repository|
      repository = repositories.find_by_github_id(remote_repository['id'])
      next unless repository.present?
      repository.subjects.each(&:destroy)
      repository.destroy
    end
  end

  def settings_url
    org_segment = account_type == 'Organization' ? "/organizations/#{account_login}" : ''
    "#{Octobox.config.github_domain}#{org_segment}/settings/installations/#{github_id}"
  end

  def github_avatar_url
    "#{Octobox.config.github_domain}/#{account_login}.png"
  end

  def private_repositories_enabled?
    return true unless Octobox.io?
    subscription_purchase.try(:private_repositories_enabled?)
  end

  def sync
    remote_installation = Octobox.github_app_client.installation(github_id, accept: 'application/vnd.github.machine-man-preview+json')
    update(AppInstallation.map_from_api(remote_installation))
  rescue Octokit::NotFound
    destroy
  end

  def sync_repositories
    remote_repositories = github_client.list_app_installation_repositories(accept: 'application/vnd.github.machine-man-preview+json').repositories
    add_repositories(remote_repositories)
  rescue Octokit::ClientError
    nil
  end

  def github_client
    Octobox.installation_client(self.github_id)
  end

  def write_issues?
    permission_issues ? permission_issues == 'write' : false
  end

  def read_issues?
    permission_issues ? ['read','write'].include?(permission_issues) : false
  end

  def self.sync_all
    remote_installations = Octobox.github_app_client.find_app_installations(accept: 'application/vnd.github.machine-man-preview+json')
    remote_installations.each do |remote_installation|
      app_installation = AppInstallation.find_or_initialize_by(github_id: remote_installation.id)
      app_installation.update(AppInstallation.map_from_api(remote_installation))
    end
  end

  def self.map_from_api(remote_installation)
    {
      github_id: remote_installation['id'],
      app_id: remote_installation['app_id'],
      account_login: remote_installation['account']['login'],
      account_id: remote_installation['account']['id'],
      account_type: remote_installation['account']['type'],
      target_type: remote_installation['target_type'],
      target_id: remote_installation['target_id'],
      permission_pull_requests: remote_installation['permissions']['pull_requests'],
      permission_issues: remote_installation['permissions']['issues'],
      permission_statuses: remote_installation['permissions']['statuses']
    }
  end
end
