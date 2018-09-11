class AppInstallation < ApplicationRecord
  has_many :repositories, dependent: :destroy
  has_many :app_installation_permissions, dependent: :delete_all
  has_many :users, through: :app_installation_permissions

  validates :github_id, presence: true, uniqueness: true
  validates :account_login, presence: true
  validates :account_id, presence: true

  def add_repositories(remote_repositories)
    remote_repositories.each do |remote_repository|
      repository = repositories.find_or_create_by(github_id: remote_repository['id'])

      repository.update_attributes({
        full_name: remote_repository['full_name'],
        private: remote_repository['private'],
        owner: remote_repository['full_name'].split('/').first,
        github_id: remote_repository['id'],
        last_synced_at: Time.current
      })

      repository.notifications.includes(:user).find_each{|n| n.update_subject(true) }
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
end
