# frozen_string_literal: true
class Notification < ApplicationRecord
  include PgSearch
  pg_search_scope :search_by_subject_title,
                  against: :subject_title,
                  using: {
                    tsearch: {
                      prefix: true,
                      negation: true,
                      dictionary: "english"
                    }
                  }

  belongs_to :user

  scope :inbox,    -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :newest,   -> { order('updated_at DESC') }
  scope :starred,  -> { where(starred: true) }

  scope :repo,     ->(repo_name)    { where(repository_full_name: repo_name) }
  scope :type,     ->(subject_type) { where(subject_type: subject_type) }
  scope :reason,   ->(reason)       { where(reason: reason) }
  scope :status,   ->(status)       { where(unread: status) }
  scope :owner,    ->(owner_name)   { where(repository_owner_name: owner_name) }

  paginates_per 20

  API_ATTRIBUTE_MAP = {
    repository_id: [:repository, :id],
    repository_full_name: [:repository, :full_name],
    repository_owner_name: [:repository, :owner, :login],
    subject_title: [:subject, :title],
    subject_type: [:subject, :type],
    subject_url: [:subject, :url],
    reason: [:reason],
    unread: [:unread],
    updated_at: [:updated_at],
    last_read_at: [:last_read_at],
    url: [:url],
    github_id: [:id]
  }.freeze

  class << self
    def download(user)
      timestamp = Time.current

      fetch_unread_notifications(user)
      fetch_read_notifications(user)

      user.update_column(:last_synced_at, timestamp)
    end

    def attributes_from_api_response(api_response)
      attrs = API_ATTRIBUTE_MAP.map do |attr, path|
        [attr, api_response.to_h.dig(*path)]
      end.to_h
      if "RepositoryInvitation" == api_response.subject.type
        attrs[:subject_url] = "#{api_response.repository.html_url}/invitations"
      end
      attrs
    end

    private

    def process_unread_notifications(notifications, user)
      return if notifications.blank?
      notifications.each do |notification|
        begin
          n =  user.notifications.find_or_initialize_by(github_id: notification[:id])
          n.update_from_api_response(notification, unarchive: true)
        rescue ActiveRecord::RecordNotUnique
          nil
        end
      end
    end

    def process_read_notifications(notifications, user)
      return if notifications.blank?
      notifications.each do |notification|
        next if notification.unread
        n = user.notifications.find_by(github_id: notification.id)
        next unless n
        n.update_from_api_response(notification)
      end
    end

    def fetch_unread_notifications(user)
      headers = {cache_control: %w(no-store no-cache)}
      headers[:if_modified_since] = user.last_synced_at.iso8601 if user.last_synced_at.respond_to?(:iso8601)
      notifications = user.github_client.notifications(headers: headers)
      process_unread_notifications(notifications, user)
    end

    def fetch_read_notifications(user)
      oldest_unread = user.notifications.status(true).newest.last
      if oldest_unread && oldest_unread.updated_at.respond_to?(:iso8601)
        headers = {cache_control: %w(no-store no-cache)}
        since = oldest_unread.updated_at - 1
        notifications = user.github_client.notifications(all: true, since: since.iso8601, headers: headers)
        process_read_notifications(notifications, user)
      end
    end
  end

  def mark_as_read
    user.github_client.mark_thread_as_read(github_id, read: true)
  end

  def ignore_thread
    user.github_client.update_thread_subscription(github_id, ignored: true)
  end

  def mute
    mark_as_read
    ignore_thread
  end

  def web_url
    subject_url.gsub("#{Octobox.github_api_prefix}/repos", Octobox.github_domain)
               .gsub('/pulls/', '/pull/')
               .gsub('/commits/', '/commit/')
               .gsub(/\/releases\/\d+/, '/releases/')
  end

  def repo_url
    "#{Octobox.github_domain}/#{repository_full_name}"
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
    save(touch: false) if changed?
  end
end
