# frozen_string_literal: true
class NotificationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :render_home_page_unless_authenticated, only: [:index]
  before_action :find_notification, only: [:archive, :unarchive, :star, :mark_read]

  def index
    scope = notifications_for_presentation
    @types                 = scope.distinct.group(:subject_type).count
    @unread_notifications  = scope.distinct.group(:unread).count
    @reasons               = scope.distinct.group(:reason).count
    @unread_repositories   = scope.distinct.group(:repository_full_name).count
    scope = current_notifications(scope)
    check_out_of_bounds(scope)

    @total = scope.count
    @notifications = scope.newest.page(page).per(per_page)
    @cur_selected = [per_page, @total].min
  end

  def unread_count
    scope = current_user.notifications
    count = scope.inbox.distinct.group(:unread).count.fetch(true){ 0 }
    render json: { 'count': count }
  end

  def mute_selected
    selected_notifications.each do |notification|
      notification.mute
      notification.update archived: true
    end
    head :ok
  end

  def archive_selected
    selected_notifications.update_all archived: params[:value]
    head :ok
  end

  def mark_read_selected
    selected_notifications.each do |notification|
      notification.mark_read(update_github: true)
    end
    head :ok
  end

  def mark_read
    @notification.update_columns unread: false
    head :ok
  end

  def star
    @notification.update_columns starred: !@notification.starred?
    head :ok
  end

  def sync
    current_user.sync_notifications
    redirect_back fallback_location: root_path
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
    sub_scopes = [:repo, :reason, :type, :unread, :owner]
    sub_scopes.each do |sub_scope|
      scope = scope.send(sub_scope, params[sub_scope]) if params[sub_scope].present?
    end
    scope = scope.search_by_subject_title(params[:q])   if params[:q].present?
    scope
  end

  def notifications_for_presentation
    scope    = current_user.notifications

    scope = if params[:starred].present?
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
    redirect_to url_for(page: page_num) if page_num != page
  end

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def render_home_page_unless_authenticated
    return render 'pages/home' unless logged_in?
  end

  def page
    params[:page].to_i rescue 1
  end

  def per_page
    per_page = params[:per_page].to_i rescue 20
    per_page = 20 if per_page < 1
    raise ActiveRecord::RecordNotFound if per_page > 100
    per_page
  end
end
