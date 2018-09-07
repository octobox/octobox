# frozen_string_literal: true
class Notification < ApplicationRecord
  SUBJECTABLE_TYPES = ['Issue', 'PullRequest', 'Commit', 'Release'].freeze

  if DatabaseConfig.is_postgres?
    include PgSearch
    pg_search_scope :search_by_subject_title,
                    against: :subject_title,
                    order_within_rank: 'notifications.updated_at DESC',
                    using: {
                      tsearch: {
                        prefix: true,
                        negation: true,
                        dictionary: "english"
                      }
                    }
  else
    def self.search_by_subject_title(title)
      where('subject_title like ?', "%#{title}%")
    end
  end

  belongs_to :user
  belongs_to :subject, foreign_key: :subject_url, primary_key: :url, optional: true
  belongs_to :repository, foreign_key: :repository_full_name, primary_key: :full_name, optional: true
  has_many :labels, through: :subject

  scope :inbox,    -> { where(archived: false) }
  scope :archived, ->(value = true) { where(archived: value) }
  scope :newest,   -> { order('notifications.updated_at DESC') }
  scope :starred,  ->(value = true) { where(starred: value) }

  scope :repo,     ->(repo_name)    { where(arel_table[:repository_full_name].matches(repo_name)) }
  scope :type,     ->(subject_type) { where(subject_type: subject_type) }
  scope :reason,   ->(reason)       { where(reason: reason) }
  scope :unread,   ->(unread)       { where(unread: unread) }
  scope :owner,    ->(owner_name)   { where(arel_table[:repository_owner_name].matches(owner_name)) }
  scope :author,    ->(author_name)   { joins(:subject).where(Subject.arel_table[:author].matches(author_name)) }

  scope :is_private, ->(is_private = true) { joins(:repository).where('repositories.private = ?', is_private) }

  scope :state,    ->(state) { joins(:subject).where('subjects.state = ?', state) }
  scope :author,    ->(author) { joins(:subject).where(Subject.arel_table[:author].matches(author)) }

  scope :labelable,   -> { where(subject_type: ['Issue', 'PullRequest']) }
  scope :label,    ->(label_name) { joins(:labels).where(Label.arel_table[:name].matches(label_name))}
  scope :unlabelled,  -> { labelable.with_subject.left_outer_joins(:labels).where(labels: {id: nil})}

  scope :assigned, ->(assignee) { joins(:subject).where("subjects.assignees LIKE ?", "%:#{assignee}:%") }
  scope :unassigned, -> { joins(:subject).where("subjects.assignees = '::'") }

  scope :subjectable, -> { where(subject_type: SUBJECTABLE_TYPES) }
  scope :with_subject, -> { includes(:subject).where.not(subjects: { url: nil }) }
  scope :without_subject, -> { includes(:subject).where(subjects: { url: nil }) }

  scope :bot_author, -> { joins(:subject).where('subjects.author LIKE ? OR subjects.author LIKE ?', '%[bot]', '%-bot') }

  paginates_per 20

  class << self
    def attributes_from_api_response(api_response)
      attrs = DownloadService::API_ATTRIBUTE_MAP.map do |attr, path|
        value = api_response.to_h.dig(*path)
        value.delete!("\u0000") if value.is_a?(String)
        [attr, value]
      end.to_h
      if "RepositoryInvitation" == api_response.subject.type
        attrs[:subject_url] = "#{api_response.repository.html_url}/invitations"
      end
      attrs
    end
  end

  def state
    return unless display_subject?
    subject.try(:state)
  end

  def self.archive(notifications, value)
    notifications.update_all(archived: ActiveRecord::Type::Boolean.new.cast(value))
    mark_read(notifications)
  end

  def self.mark_read(notifications)
    unread = notifications.select(&:unread)
    return if unread.empty?
    user = unread.first.user
    conn = user.github_client.client_without_redirects
    manager = Typhoeus::Hydra.new(max_concurrency: Octobox.config.max_concurrency)
    begin
      conn.in_parallel(manager) do
        unread.each do |n|
            conn.patch "notifications/threads/#{n.github_id}"
        end
      end
    rescue Octokit::Forbidden, Octokit::NotFound
      # one or more notifications are for repos the user no longer has access to
    end
    where(id: unread.map(&:id)).update_all(unread: false)
  end

  def self.mute(notifications)
    return if notifications.empty?
    user = notifications.to_a.first.user
    conn = user.github_client.client_without_redirects
    manager = Typhoeus::Hydra.new(max_concurrency: Octobox.config.max_concurrency)
    conn.in_parallel(manager) do
      notifications.each do |n|
        conn.patch "notifications/threads/#{n.github_id}"
        conn.put "notifications/threads/#{n.github_id}/subscription", {ignored: true}.to_json
      end
    end

    where(id: notifications.map(&:id)).update_all(archived: true, unread: false)
  end

  def expanded_subject_url
    return subject_url unless Octobox.config.subjects_enabled?
    subject.try(:html_url) || subject_url # Use the sync'd HTML URL if possible, else the API one
  end

  def web_url
    Octobox::SubjectUrlParser.new(expanded_subject_url, latest_comment_url: latest_comment_url)
      .to_html_url
  end

  def repo_url
    "#{Octobox.config.github_domain}/#{repository_full_name}"
  end

  def unarchive_if_updated
    return unless self.archived?
    change = changes['updated_at']
    return unless change
    if self.archived && change[1] > change[0]
      self.archived = false
    end
  end

  def update_from_api_response(api_response, unarchive: false)
    attrs = Notification.attributes_from_api_response(api_response)
    self.attributes = attrs
    unarchive_if_updated if unarchive
    self
    update_subject
    update_repository
  end

  def github_app_installed?
    user.app_token.present? && repository.try(:github_app_installed?)
  end

  def subjectable?
    SUBJECTABLE_TYPES.include?(subject_type)
  end

  def display_subject?
    github_app_installed? || Octobox.fetch_subject?
  end

  def update_subject(force = false)
    return unless subjectable?
    return unless display_subject?

    UpdateSubjectWorker.perform_async_if_configured(self.id, force)
  end

  def update_subject_in_foreground(force = false)
    return unless subjectable?
    return unless display_subject?
    # skip syncing if the notification was updated around the same time as subject
    return if !force && subject != nil && updated_at - subject.updated_at < 2.seconds

    remote_subject = download_subject
    return unless remote_subject.present?

    if subject
      case subject_type
      when 'Issue', 'PullRequest'
        subject.repository_full_name = repository_full_name
        subject.assignees = ":#{Array(remote_subject.assignees.try(:map, &:login)).join(':')}:"
        subject.state = remote_subject.merged_at.present? ? 'merged' : remote_subject.state
        subject.save(touch: false) if subject.changed?
      end
    else
      case subject_type
      when 'Issue', 'PullRequest'
        create_subject({
          repository_full_name: repository_full_name,
          github_id: remote_subject.id,
          state: remote_subject.merged_at.present? ? 'merged' : remote_subject.state,
          author: remote_subject.user.login,
          html_url: remote_subject.html_url,
          created_at: remote_subject.created_at,
          updated_at: remote_subject.updated_at,
          assignees: ":#{Array(remote_subject.assignees.try(:map, &:login)).join(':')}:"
        })
      when 'Commit', 'Release'
        create_subject({
          repository_full_name: repository_full_name,
          github_id: remote_subject.id,
          author: remote_subject.author&.login,
          html_url: remote_subject.html_url,
          created_at: remote_subject.created_at,
          updated_at: remote_subject.updated_at
        })
      end
    end

    case subject_type
    when 'Issue', 'PullRequest'
      subject.update_labels(remote_subject.labels) if remote_subject.labels.present?
    end
  end

  private

  def download_subject
    user.subject_client.get(subject_url)

  # If permissions changed and the user hasn't accepted, we get a 401
  # We may receive a 403 Forbidden or a 403 Not Available
  # We may be rate limited and get a 403 as well
  # We may also get blocked by legal reasons (451)
  # Regardless of the reason, any client error should be rescued and warned so we don't
  # end up blocking other syncs
  rescue Octokit::ClientError => e
    Rails.logger.warn("\n\n\033[32m[#{Time.now}] WARNING -- #{e.message}\033[0m\n\n")
    nil
  end

  def download_repository
    user.github_client.repository(repository_full_name)
  rescue Octokit::ClientError => e
    nil
  end

  def update_repository
    return unless display_subject?
    return if repository != nil && updated_at - repository.updated_at < 2.seconds

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
end
