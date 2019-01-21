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
    github_id: [:id],
    latest_comment_url: [:subject, :latest_comment_url]
  }.freeze

  def download
    timestamp = Time.current
    fetch_new_notifications
    fetch_all_notifications
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

  def fetch_new_notifications
    headers = {cache_control: %w(no-store no-cache)}
    headers[:if_modified_since] = user.last_synced_at.iso8601 if user.last_synced_at.respond_to?(:iso8601)
    notifications = fetch_notifications(params: {all: true, headers: headers})
    process_notifications(notifications)
  end

  def fetch_all_notifications
    headers = {cache_control: %w(no-store no-cache)}
    notifications = fetch_notifications(params: {all: true, headers: headers})
    process_unread_state(notifications)
  end

  def process_notifications(notifications)
    return if notifications.blank?
    eager_load_relation = Octobox.config.subjects_enabled? ? [:subject, :repository, :app_installation] : nil
    existing_notifications = user.notifications.includes(eager_load_relation).where(github_id: notifications.map(&:id))
    notifications.each do |notification|
      n = existing_notifications.find{|en| en.github_id == notification.id.to_i}
      n = user.notifications.new(github_id: notification.id, archived: false) if n.nil?
      next unless n
      begin
        n.update_from_api_response(notification)
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end

  def process_unread_state(notifications)
    return if notifications.blank?

    existing_notifications = user.notifications.where(github_id: notifications.map(&:id)).select('id, github_id, unread')
    notifications.each do |notification|
      n = existing_notifications.find{|en| en.github_id == notification.id.to_i}
      next unless n
      begin
        n.update_column(:unread, notification['unread']) if n.unread != notification['unread']
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end
end
