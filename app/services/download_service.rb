
class DownloadService
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def github_client
    user.github_client
  end

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

  def process_unread_notifications(notifications)
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

  def process_read_notifications(notifications)
    return if notifications.blank?
    notifications.each do |notification|
      next if notification.unread
      n = user.notifications.find_or_initialize_by(github_id: notification.id)
      next unless n
      n.update_from_api_response(notification)
    end
  end

  def fetch_unread_notifications
    headers = {cache_control: %w(no-store no-cache)}
    headers[:if_modified_since] = user.last_synced_at.iso8601 if user.last_synced_at.respond_to?(:iso8601)
    notifications = user.github_client.notifications(headers: headers)
    process_unread_notifications(notifications)
  end

  def fetch_read_notifications
    oldest_unread = user.notifications.status(true).newest.last
    if oldest_unread && oldest_unread.updated_at.respond_to?(:iso8601)
      headers = {cache_control: %w(no-store no-cache)}
      since = oldest_unread.updated_at - 1
      notifications = user.github_client.notifications(all: true, since: since.iso8601, headers: headers)
      process_read_notifications(notifications)
    end
  end

  def new_user_fetch
    headers = {cache_control: %w(no-store no-cache)}
    notifications = user.github_client.notifications(all: true, headers: headers)
    process_read_notifications(notifications)
  end

  def download
    timestamp = Time.current

    if user.last_synced_at
      fetch_read_notifications
    else
      new_user_fetch
    end
    fetch_unread_notifications
    user.update_column(:last_synced_at, timestamp)
  end
end
