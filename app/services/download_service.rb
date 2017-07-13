
class DownloadService
  attr_accessor :user

  def initialize(user)
    @user = user
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

  private

  def page_limiting_client
    @page_limiting_client ||= user.github_client.dup.extend(PageLimitingOctokitClient)
  end

  def fetch_notifications(params: {}, max_results: Octobox.config.max_notifications_to_sync)
    client = page_limiting_client
    params[:max_results] = max_results
    client.notifications(params)
  end

  def fetch_unread_notifications
    headers = {cache_control: %w(no-store no-cache)}
    headers[:if_modified_since] = user.last_synced_at.iso8601 if user.last_synced_at.respond_to?(:iso8601)
    notifications = fetch_notifications(params: {headers: headers})
    process_unread_notifications(notifications)
  end

  def fetch_read_notifications
    oldest_unread = user.notifications.unread(true).newest.last
    if oldest_unread && oldest_unread.updated_at.respond_to?(:iso8601)
      headers = {cache_control: %w(no-store no-cache)}
      since = oldest_unread.updated_at - 1
      notifications = fetch_notifications(params: {all: true, since: since.iso8601, headers: headers})
      process_read_notifications(notifications)
    end
  end

  def process_unread_notifications(notifications)
    return if notifications.blank?
    existing_notifications = user.notifications.where(github_id: notifications.map(&:id))
    notifications.each do |notification|
      begin
        n = existing_notifications.find{|n| n.github_id == notification.id.to_i}
        n = user.notifications.new(github_id: notification.id) if n.nil?
        n.update_from_api_response(notification, unarchive: true)
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end

  def process_read_notifications(notifications)
    return if notifications.blank?
    existing_notifications = user.notifications.where(github_id: notifications.map(&:id))
    notifications.each do |notification|
      next if notification.unread
      n = existing_notifications.find{|n| n.github_id == notification.id.to_i }
      n = user.notifications.new(github_id: notification.id) if n.nil?
      next unless n
      n.update_from_api_response(notification)
    end
  end

  def new_user_fetch
    headers = {cache_control: %w(no-store no-cache)}
    notifications = fetch_notifications(params: {all: true, headers: headers})
    process_read_notifications(notifications)
  end
end
