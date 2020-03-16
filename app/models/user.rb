# frozen_string_literal: true
class User < ApplicationRecord
  attr_encrypted :access_token, key: Octobox.config.attr_encyrption_key
  attr_encrypted :personal_access_token, key: Octobox.config.attr_encyrption_key
  attr_encrypted :app_token, key: Octobox.config.attr_encyrption_key

  has_secure_token :api_token
  has_many :notifications, dependent: :delete_all
  has_many :app_installation_permissions, dependent: :delete_all
  has_many :app_installations, through: :app_installation_permissions
  has_many :pinned_searches, dependent: :delete_all
  has_one :individual_subscription_purchase, foreign_key: :account_id, primary_key: :github_id, class_name: 'SubscriptionPurchase'

  ERRORS = {
    refresh_interval_size: [:refresh_interval, 'must be less than 1 day']
  }.freeze

  validates :github_id,    presence: true, uniqueness: true
  validates :encrypted_access_token, uniqueness: true, allow_blank: true
  validates :github_login, presence: true
  validates :refresh_interval, numericality: {
    only_integer: true,
    allow_blank: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 86_400_000,
    message: ERRORS[:refresh_interval_size][1]
  }
  validates_with PersonalAccessTokenValidator

  scope :not_recently_synced, -> { where('last_synced_at < ?', 5.minutes.ago) }
  scope :with_access_token, -> { where.not(encrypted_access_token: nil) }

  after_create :create_default_pinned_searches

  def admin?
    Octobox.config.github_admin_ids.include?(github_id.to_s)
  end

  def github_app_authorized?
    encrypted_app_token.present?
  end

  def refresh_interval=(val)
    val = nil if 0 == val
    super(val)
  end

  def has_personal_plan?
    individual_subscription_purchase && individual_subscription_purchase.private_repositories_enabled?
  end

  # For users who had zero values set before 20170111185505_allow_null_for_last_synced_at_in_users.rb
  # We want their zeros treated like nils
  def refresh_interval
    0 == super ? nil : super
  end

  def self.find_by_auth_hash(auth_hash)
    User.find_by(github_id: auth_hash['uid'])
  end

  def assign_from_auth_hash(auth_hash, app = 'github')
    token_field = app == 'github' ? :access_token : :app_token
    github_attributes = {
      github_id: auth_hash['uid'],
      github_login: auth_hash['info']['nickname'],
      token_field => auth_hash.dig('credentials', 'token')
    }

    update!(github_attributes)
  end

  def syncing?
    return false unless Octobox.background_jobs_enabled? && sync_job_id
    # We are syncing if we are queued or working, all other states mean we are not working
    [:queued, :working].include?(Sidekiq::Status.status(sync_job_id))
  end

  def sync_notifications
    return true if syncing?
    job_id = SyncNotificationsWorker.perform_async_if_configured(self.id)
    update(sync_job_id: job_id)
    SyncInstallationPermissionsWorker.perform_async_if_configured(self.id) if github_app_authorized?
  end

  def sync_notifications_in_foreground
    download_service.download
    Rails.logger.info("\n\n\033[32m[#{Time.current}] INFO -- #{github_login} synced their notifications\033[0m\n\n")
  rescue Octokit::Unauthorized => e
    Rails.logger.warn("\n\n\033[32m[#{Time.current}] INFO -- #{github_login} failed to sync notifications -- #{e.message}\033[0m\n\n")
  end

  def download_service
    @download_service ||= DownloadService.new(self)
  end

  def github_client
    personal_access_token_client || access_token_client
  end

  def personal_access_token_client
    @personal_access_token_client ||= Octokit::Client.new(access_token: personal_access_token, auto_paginate: true) if personal_access_token_enabled?
  end

  def access_token_client
    @access_token_client ||= Octokit::Client.new(access_token: access_token, auto_paginate: true) if access_token.present?
  end

  def comment_client(comment)
    return app_installation_client if app_token.present? && comment.subject.repository.commentable?
    return github_client
  end

  def app_installation_client
    Octokit::Client.new(access_token: app_token, auto_paginate: true) if app_token.present?
  end

  def github_avatar_url
    "#{Octobox.config.github_domain}/#{github_login}.png"
  end

  # Use the greater of the system minimum or the user's setting
  def effective_refresh_interval
    if Octobox.refresh_interval_enabled? && refresh_interval
      [Octobox.config.minimum_refresh_interval * 60_000, refresh_interval].max
    end
  end

  def effective_access_token
    github_client&.access_token
  end

  def masked_personal_access_token
    personal_access_token.blank? ? '' :
    "#{'*' * 32}#{personal_access_token.slice(-8..-1)}"
  end

  def personal_access_token_enabled?
    Octobox.personal_access_tokens_enabled? && personal_access_token.present?
  end

  def sync_app_installation_access
    return unless github_app_authorized?
    remote_installs = app_installation_client.find_user_installations(accept: 'application/vnd.github.machine-man-preview+json')
    app_installations = AppInstallation.where(github_id: remote_installs[:installations].map(&:id))
    app_installations.each do |app_installation|
      app_installation_permissions.find_or_create_by(app_installation_id: app_installation.id)
    end
    app_installation_ids = app_installations.map(&:id)
    removed_permissions = app_installation_permissions.reject{|ep| app_installation_ids.include?(ep.app_installation_id) }
    removed_permissions.each(&:destroy)
  end

  def has_app_installed?(subject)
    subject.repository.app_installation_id && app_token
  end

  def can_comment?(subject)
    return false unless subject.commentable?
    return true if personal_access_token_enabled?
    return true if Octobox.fetch_subject?
    return true if github_app_authorized? && subject.repository && subject.repository.commentable?
    return false
  end

  def create_default_pinned_searches
    pinned_searches.create(query: 'state:closed,merged archived:false', name: 'Archivable')
    pinned_searches.create(query: 'type:pull_request state:open status:success archived:false', name: 'Mergeable')
    pinned_searches.create(query: "type:pull_request author:#{github_login} inbox:true", name: 'My PRs')
  end

  def import_notifications(data)
    data.each do |new_notification|
      n = self.notifications.find_or_initialize_by(github_id: new_notification['github_id'])
      n.attributes = new_notification.except('id', 'user_id')
      n.save(touch: false) if n.changed?
    end
  end
end
