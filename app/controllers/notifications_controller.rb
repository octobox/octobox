# frozen_string_literal: true
class NotificationsController < ApplicationController
  include NotificationsConcern

  skip_before_action :authenticate_user!
  before_action :authenticate_web_or_api!
  before_action :find_notification, only: [:star]

  # Return a listing of notifications, including a summary of unread repos, notification reasons, and notification types
  #
  # :category: Notifications CRUD
  #
  # ==== Parameters
  #
  # * +:page+ - The page you would like to request
  # * +:per_page+ - The number of results you would like to return per page. Max 100, default 20.
  # * +:starred+ - Return only the user's starred notifications
  # * +:archive+ - Return only the user's archived notifications
  # * +:q+ - Search by subject title of the notification
  #
  # ==== Notes
  #
  # If the +:per_page+ paremeter is set to more than 100, a 404 will be returned
  #
  # ==== Example
  #
  # <code>GET api/notifications.json</code>
  #
  #   {
  #      "pagination" : {
  #         "total_notifications" : 1,
  #         "page" : 1,
  #         "total_pages" : 1,
  #         "per_page" : 20
  #      },
  #      "types" : {
  #         "PullRequest" : 1,
  #      },
  #      "reasons" : {
  #         "mention" : 1
  #      },
  #      "unread_repositories" : {
  #         "octobox/octobox" : 1
  #      },
  #      "notifications" : [
  #         {
  #            "id" : 29,
  #            "github_id" :  320,
  #            "reason" :  "mention",
  #            "unread" :  true,
  #            "archived" :  false,
  #            "starred" :  false,
  #            "url" : "https://api.github.com/notifications/threads/320",
  #            "web_url" : "https://github.com/octobox/octobox/pull/320",
  #            "last_read_at" : "2017-02-20 22:26:11 UTC",
  #            "created_at" : "2017-02-22T15:49:33.750Z",
  #            "updated_at" : "2017-02-22T15:40:21.000Z",
  #            "subject":{
  #               "title" : "Add JSON API",
  #               "url" : "https://api.github.com/repos/octobox/octobox/pulls/320",
  #               "type" : "PullRequest",
  #               "state" : "merged"
  #            },
  #            "repo":{
  #               "id": 320,
  #               "name" : "octobox/octobox",
  #               "owner" : "octobox",
  #               "repo_url" : "https://github.com/octobox/octobox"
  #            }
  #         }
  #      ]
  #   }
  #
  def index
    load_and_count_notifications
  end

  # @private doesn't have an api yet
  def show
    scope = notifications_for_presentation.newest
    scope = load_and_count_notifications(scope) unless request.xhr?

    ids = scope.pluck(:id)
    position = ids.index(params[:id].to_i)
    @notification = current_user.notifications.find(params[:id])
    @previous = ids[position-1] unless position.nil? || position-1 < 0
    @next = ids[position+1] unless position.nil? || position+1 > ids.length

    if @notification.subject && @notification.subject.commentable?
      comments_loaded = 5
      @comments = @notification.subject.comments.order('created_at DESC').limit(comments_loaded).reverse
      @comments_left_to_load = @notification.subject.comment_count - comments_loaded
      @comments_left_to_load = 0 if @comments_left_to_load < 0
    else
      @comments = []
    end

    render partial: "notifications/thread", layout: false if request.xhr?
  end

  # @private doesn't have an api yet
  def expand_comments
    scope = notifications_for_presentation.newest
    scope = load_and_count_notifications(scope) unless request.xhr?

    ids = scope.pluck(:id)
    position = ids.index(params[:id].to_i)
    @notification = current_user.notifications.find(params[:id])
    @previous = ids[position-1] unless position.nil? || position-1 < 0
    @next = ids[position+1] unless position.nil? || position+1 > ids.length

    @comments_left_to_load = 0

    if @notification.subject
      @comments = @notification.subject.comments.order('created_at ASC')
    else
      @comments = []
    end

    if request.xhr?
      render partial: "notifications/comments", locals:{comments: @comments}, layout: false
    else
      render 'notifications/show'
    end
  end

  # @private doesn't have an api yet
  def comment
    subject = current_user.notifications.find(params[:id]).subject

    if current_user.can_comment?(subject)
      subject.comment(current_user, params[:comment][:body]) if subject.commentable?
      if request.xhr?
        render partial: "notifications/comments", locals:{comments: subject.comments.last}, layout: false
      else
        redirect_back fallback_location: notification_path
      end
    else
      flash[:error] = 'Could not post your comment'
      redirect_back fallback_location: notification_path
    end
  end

  # Return a count for the number of unread notifications
  #
  # :category: Notifications CRUD
  #
  # ==== Example
  #
  # <code>GET api/notifications/unread_count.json</code>
  #   { "count" : 1 }
  #
  def unread_count
    render json: { 'count' => user_unread_count }
  end

  # Find a notification by it's subject url
  #
  # ==== Parameters
  #
  # * +:url+ - github url of subject
  #
  # ==== Example
  #
  # <code>GET api/notifications/lookup.json</code>
  # {
  #    "id" : 29,
  #    "github_id" :  320,
  #    "reason" :  "mention",
  #    "unread" :  true,
  #    "archived" :  false,
  #    "starred" :  false,
  #    "url" : "https://api.github.com/notifications/threads/320",
  #    "web_url" : "https://github.com/octobox/octobox/pull/320",
  #    "last_read_at" : "2017-02-20 22:26:11 UTC",
  #    "created_at" : "2017-02-22T15:49:33.750Z",
  #    "updated_at" : "2017-02-22T15:40:21.000Z",
  #    "subject":{
  #       "title" : "Add JSON API",
  #       "url" : "https://api.github.com/repos/octobox/octobox/pulls/320",
  #       "type" : "PullRequest",
  #       "state" : "merged"
  #    },
  #    "repo":{
  #       "id": 320,
  #       "name" : "octobox/octobox",
  #       "owner" : "octobox",
  #       "repo_url" : "https://github.com/octobox/octobox"
  #    }
  # }
  #
  def lookup
    if params[:url].present?
      url = Octobox::SubjectUrlParser.new(params[:url]).to_api_url
      @notification = current_user.notifications.where(subject_url: url).first
      render json: {} if @notification.nil?
    else
      render json: {}
    end
  end

  # Mute selected notifications, this will also archive them
  #
  # :category: Notifications Actions
  #
  # ==== Parameters
  #
  # * +:id+ - An array of IDs of notifications you'd like to mute. If ID is 'all', all notifications will be muted
  #
  # ==== Example
  #
  # <code>POST api/notifications/mute_selected.json?id=all</code>
  #   HEAD 204
  #
  def mute_selected
    Notification.mute(selected_notifications)
    if request.xhr?
      head :ok
    else
      redirect_back fallback_location: root_path
    end
  end

  # Archive selected notifications
  #
  # :category: Notifications Actions
  #
  # ==== Parameters
  #
  # * +:id+ - An array of IDs of notifications you'd like to archive. If ID is 'all', all notifications will be archived
  #
  # ==== Example
  #
  # <code>POST api/notifications/archive_selected.json?id=all</code>
  #   HEAD 204
  #
  def archive_selected
    Notification.archive(selected_notifications, params[:value])
    if request.xhr?
      head :ok
    else
      redirect_back fallback_location: root_path
    end
  end

  # Mark selected notifications as read
  #
  # :category: Notifications Actions
  #
  # ==== Parameters
  #
  # * +:id+ - An array of IDs of notifications you'd like to mark as read. If ID is 'all', all notifications will be marked as read
  #
  # ==== Example
  #
  # <code>POST api/notifications/mark_read_selected.json?id=all</code>
  #   HEAD 204
  #
  def mark_read_selected
    Notification.mark_read(selected_notifications)
    head :ok
  end

  # Delete selected notifications
  #
  # :category: Notifications Actions
  #
  # ==== Parameters
  #
  # * +:id+ - An array of IDs of notifications you'd like to delete. If ID is 'all', all notifications will be deleted
  #
  # ==== Example
  #
  # <code>POST api/notifications/delete_selected.json?id=all</code>
  #   HEAD 204
  #
  def delete_selected
    selected_notifications.delete_all
    if request.xhr?
      head :ok
    else
      redirect_back fallback_location: root_path
    end
  end

  # Star a notification
  #
  # :category: Notifications Actions
  #
  # ==== Example
  #
  # <code>POST api/notifications/:id/star.json</code>
  #   HEAD 204
  #
  def star
    @notification.update_columns starred: !@notification.starred?
    head :ok
  end

  # Synchronize notifications with GitHub
  #
  # :category: Notifications Actions
  #
  # ==== Example
  #
  # <code>POST api/notifications/sync.json</code>
  #   HEAD 204
  #
  def sync
    if Octobox.background_jobs_enabled?
      current_user.sync_notifications
    else
      current_user.sync_notifications_in_foreground
    end

    respond_to do |format|
      format.html do
        if request.referer && !request.referer.match('/notifications/sync')
          redirect_back fallback_location: root_path
        else
          redirect_to root_path
        end
      end
      format.json { {} }
    end
  end

  # Check if user is synchronizing notifications with GitHub
  #
  # ==== Example
  #
  # <code>POST api/notifications/syncing.json</code>
  #   {} 204 (ok)
  #
  # <code>POST api/notifications/syncing.json</code>
  #   {} 423 (locked)
  #
  def syncing
    if current_user.syncing?
      render json: {}, status: :locked
    else
      render json: { error: Sidekiq::Status::get(current_user.sync_job_id, :exception) }, status: :ok
    end
  end
end
