# frozen_string_literal: true
class NotificationsController < ApplicationController

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
  # <code>GET notifications.json</code>
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
  # <code>GET notifications/unread_count.json</code>
  #   { "count" : 1 }
  #
  def unread_count
    render json: { 'count' => user_unread_count }
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
  # <code>POST notifications/mute_selected.json?id=all</code>
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
  # <code>POST notifications/archive_selected.json?id=all</code>
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
  # <code>POST notifications/mark_read_selected.json?id=all</code>
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
  # <code>POST notifications/delete_selected.json?id=all</code>
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
  # <code>POST notifications/:id/star.json</code>
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
  # <code>POST notifications/sync.json</code>
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
  # <code>POST notifications/syncing.json</code>
  #   {} 204 (ok)
  #
  # <code>POST notifications/syncing.json</code>
  #   {} 423 (locked)
  #
  def syncing
    if current_user.syncing?
      render json: {}, status: :locked
    else
      render json: { error: Sidekiq::Status::get(current_user.sync_job_id, :exception) }, status: :ok
    end
  end

  private

  def load_and_count_notifications(scope = notifications_for_presentation.newest)
    @types                 = scope.reorder(nil).distinct.group(:subject_type).count
    @unread_notifications  = scope.reorder(nil).distinct.group(:unread).count
    @reasons               = scope.reorder(nil).distinct.group(:reason).count
    @unread_repositories   = scope.reorder(nil).distinct.group(:repository_full_name).count

    @review_requested      = scope.reorder(nil).distinct.requested_reviewers(current_user.github_login).count
    @states                = scope.reorder(nil).distinct.joins(:subject).group('subjects.state').count
    @statuses              = scope.reorder(nil).distinct.joins(:subject).group('subjects.status').count
    @unlabelled            = scope.reorder(nil).unlabelled.count
    @bot_notifications     = scope.reorder(nil).bot_author.count
    @draft                 = scope.reorder(nil).draft.count
    @assigned              = scope.reorder(nil).assigned(current_user.github_login).count
    @visiblity             = scope.reorder(nil).distinct.joins(:repository).group('repositories.private').count
    @repositories          = Repository.where(full_name: scope.reorder(nil).distinct.pluck(:repository_full_name)).select('full_name,private')

    scope = current_notifications(scope)
    check_out_of_bounds(scope)

    @unread_count = user_unread_count
    @pagy, @notifications = pagy(scope, items: per_page, size: [1,2,2,1])
    @total = @pagy.count

    @cur_selected = [per_page, @total].min
    return scope
  end

  def user_unread_count
    current_user.notifications.inbox.distinct.group(:unread).count.fetch(true){ 0 }
  end

  def selected_notifications
    if params[:id] == ['all']
      current_notifications
    else
      current_user.notifications.where(id: params[:id])
    end
  end

  def current_notifications(scope = notifications_for_presentation)
    [:repo, :reason, :type, :unread, :owner, :state, :author, :is_private, :status, :draft, :requested_reviewers].each do |sub_scope|
      next unless params[sub_scope].present?
      # This cast is required due to a bug in type casting
      # TODO: Rails 5.2 was supposed to fix this:
      # https://github.com/rails/rails/commit/68fe6b08ee72cc47263e0d2c9ff07f75c4b42761
      # but it seems that the issue persists when using MySQL
      # https://github.com/rails/rails/issues/32624
      if sub_scope == :reason || :requested_reviewers
        val = params[sub_scope].split(',')
      else
        val = scope.klass.type_for_attribute(sub_scope.to_s).cast(params[sub_scope])
      end
      scope = scope.send(sub_scope, val)
    end
    scope = scope.unlabelled if params[:unlabelled].present?
    scope = scope.bot_author(params[:bot]) if params[:bot].present?
    scope = scope.label(params[:label]) if params[:label].present?
    scope = scope.assigned(params[:assigned]) if params[:assigned].present?
    scope
  end

  def notifications_for_presentation
    @search = Search.initialize_for_saved_search(query: params[:q], user: current_user, params: params)

    if params[:q].present?
      @search.results
    elsif params[:starred].present?
      @search.scope.starred
    elsif params[:archive].present?
      @search.scope.archived
    else
      @search.scope.inbox
    end
  end

  def check_out_of_bounds(scope)
    return unless page > 1
    total_pages = (scope.count / per_page.to_f).ceil
    page_num = [page, total_pages].min
    redirect_params = params.permit!.merge(page: page_num)
    redirect_to url_for(redirect_params) if page_num != page
  end

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def authenticate_web_or_api!
    return if logged_in?
    respond_to do |format|
      format.html { render 'pages/home' }
      format.json { authenticate_user! }
    end
  end

  def page
    @page ||= params[:page].to_i rescue 1
  end

  def per_page
    @per_page ||= restrict_per_page
  end

  DEFAULT_PER_PAGE = 20

  def restrict_per_page
    per_page = per_page_param || per_page_cookie || DEFAULT_PER_PAGE

    return DEFAULT_PER_PAGE if per_page < 1
    raise ActiveRecord::RecordNotFound if per_page > 100
    cookies[:per_page] = per_page

    per_page
  end

  def per_page_param
    Integer(params[:per_page]) rescue nil
  end

  def per_page_cookie
    Integer(cookies[:per_page]) rescue nil
  end
end
