class Repository < ApplicationRecord

  include Octobox::Repository::UpdateNotificationRepositoryName

  has_many :notifications, foreign_key: :repository_full_name, primary_key: :full_name
  has_many :users, -> { distinct }, through: :notifications
  has_many :subjects, foreign_key: :repository_full_name, primary_key: :full_name
  belongs_to :app_installation, optional: true

  validates :full_name, presence: true, uniqueness: true
  validates :github_id, uniqueness: true

  scope :github_app_installed, -> { joins(:app_installation) }

  def open_source?
    !private?
  end

  def github_app_installed?
    app_installation_id.present?
  end

  def commentable?
    return true if Octobox.fetch_subject?
    github_app_installed? && app_installation.write_issues?
  end

  def display_subject?
    return true unless private?
    github_app_installed? && required_plan_available?
  end

  def required_plan_available?
    return true unless Octobox.io?
    private? ? app_installation.private_repositories_enabled? : true
  end

  def self.sync(remote_repository)
    repository = Repository.find_or_create_by(github_id: remote_repository['id'])

    repository.update({
      full_name: remote_repository['full_name'],
      private: remote_repository['private'],
      owner: remote_repository['full_name'].split('/').first,
      github_id: remote_repository['id'],
      last_synced_at: Time.current
    })
  end

  def sync_subjects
    UpdateRepoSubjectsWorker.perform_async_if_configured(self.id)
  end

  def sync_subjects_in_foreground
    subject_urls = notifications.subjectable.distinct.pluck(:subject_url)
    return unless app_installation
    client = app_installation.github_client
    subject_urls.each do |subject_url|
      begin
        remote_subject = client.get(subject_url)
        SyncSubjectWorker.perform_async_if_configured(remote_subject.to_h)
      rescue Octokit::ClientError, Octokit::Forbidden => e
        Rails.logger.warn("\n\n\033[32m[#{Time.current}] WARNING -- #{e.message}\033[0m\n\n")
        nil
      end
    end
  end
end
