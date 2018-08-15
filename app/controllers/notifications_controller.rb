# frozen_string_literal: true
class NotificationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_web_or_api!
  before_action :find_notification, only: [:star, :mark_read]

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
    scope = notifications_for_presentation
    @types                 = scope.distinct.group(:subject_type).count
    @unread_notifications  = scope.distinct.group(:unread).count
    @reasons               = scope.distinct.group(:reason).count
    @unread_repositories   = scope.distinct.group(:repository_full_name).count

    if Octobox.config.fetch_subject
      @states                = scope.distinct.joins(:subject).group('subjects.state').count
      @unlabelled            = scope.unlabelled.count
      @bot_notifications     = scope.bot_author.count
    end

    scope = current_notifications(scope)
    check_out_of_bounds(scope)

    @total = scope.count

    @notifications = scope.newest.page(page).per(per_page)
    @cur_selected = [per_page, @total].min
  end

  def show
    scope = notifications_for_presentation
    @types                 = scope.distinct.group(:subject_type).count
    @unread_notifications  = scope.distinct.group(:unread).count
    @reasons               = scope.distinct.group(:reason).count
    @unread_repositories   = scope.distinct.group(:repository_full_name).count

    if Octobox.config.fetch_subject
      @states                = scope.distinct.joins(:subject).group('subjects.state').count
      @unlabelled            = scope.unlabelled.count
      @bot_notifications     = scope.bot_author.count
    end

    scope =  current_notifications(scope).newest
    ids = scope.map(&:id)
    position = ids.index(params[:id].to_i)

    @notification = scope.find(params[:id])
    @previous = scope.find(ids[position-1]) unless position-1 < 0
    @next = scope.find(ids[position+1]) unless position+1 > ids.length
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
    scope = current_user.notifications
    count = scope.inbox.distinct.group(:unread).count.fetch(true){ 0 }
    render json: { 'count' => count }
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
    head :ok
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
    selected_notifications.update_all(
      archived: ActiveRecord::Type::Boolean.new.cast(params[:value])
    )
    head :ok
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

  # Mark a notification as read
  #
  # :category: Notifications Actions
  #
  # ==== Example
  #
  # <code>POST notifications/:id/mark_read.json</code>
  #   HEAD 204
  #
  def mark_read
    @notification.update_columns unread: false
    head :ok
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
    current_user.sync_notifications
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.json { head :ok }
    end
  end

  private

  def selected_notifications
    if params[:id] == ['all']
      current_notifications
    else
      current_user.notifications.where(id: params[:id])
    end
  end

  def current_notifications(scope = notifications_for_presentation)
    [:repo, :reason, :type, :unread, :owner, :state].each do |sub_scope|
      next unless params[sub_scope].present?
      # This cast is required due to a bug in type casting
      # TODO: Rails 5.2 was supposed to fix this:
      # https://github.com/rails/rails/commit/68fe6b08ee72cc47263e0d2c9ff07f75c4b42761
      # but it seems that the issue persists when using MySQL
      # https://github.com/rails/rails/issues/32624
      if sub_scope == :reason
        val = params[sub_scope].split(',')
      else
        type = scope.klass.type_for_attribute(sub_scope.to_s).class
        val = scope.klass.type_for_attribute(sub_scope.to_s).cast(params[sub_scope])
      end
      scope = scope.send(sub_scope, val)
    end
    scope = scope.unlabelled if params[:unlabelled].present?
    scope = scope.bot_author if params[:bot].present?
    scope = scope.labels(params[:label]) if params[:label].present?
    scope = scope.search_by_subject_title(params[:q]) if params[:q].present?
    scope = scope.unscope(where: :archived)           if params[:q].present?
    scope
  end

  def notifications_for_presentation
    eager_load_relation = Octobox.config.fetch_subject ? {subject: [:labels, :comments]} : nil
    scope = current_user.notifications.includes(eager_load_relation)

    if params[:starred].present?
      scope.starred
    elsif params[:archive].present?
      scope.archived
    else
      scope.inbox
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

  def restrict_per_page
    per_page = params[:per_page].to_i rescue 20
    per_page = 20 if per_page < 1
    raise ActiveRecord::RecordNotFound if per_page > 100
    per_page
  end
end
