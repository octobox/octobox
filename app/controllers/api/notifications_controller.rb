class Api::NotificationsController < Api::ApplicationController
  include NotificationsConcern

  before_action :authenticate_user!

  def index
    load_notifications
  end

  def star
    find_notification
    @notification.update_columns starred: !@notification.starred?
    head :ok
  end

  def syncing
    if current_user.syncing?
      render json: {}, status: :locked
    else
      render json: { error: Sidekiq::Status::get(current_user.sync_job_id, :exception) }, status: :ok
    end
  end

  def sync
    if Octobox.background_jobs_enabled?
      current_user.sync_notifications
    else
      current_user.sync_notifications_in_foreground
    end

    render json: {}
  end

  def unread_count
    render json: { 'count' => user_unread_count }
  end

  def lookup
    if params[:url].present?
      url = Octobox::SubjectUrlParser.new(params[:url]).to_api_url
      @notification = current_user.notifications.where(subject_url: url).first
      render json: {} if @notification.nil?
    else
      render json: {}
    end
  end

  def mute_selected
    Notification.mute(selected_notifications)
    head :ok
  end

  def archive_selected
    Notification.archive(selected_notifications, params[:value])
    head :ok
  end

  def mark_read_selected
    Notification.mark_read(selected_notifications)
    head :ok
  end

  def delete_selected
    selected_notifications.delete_all
    head :ok
  end

  private

  def per_page_cookie
    nil
  end
end
