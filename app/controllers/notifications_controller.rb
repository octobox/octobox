# frozen_string_literal: true
class NotificationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :render_home_page_unless_authenticated, only: [:index]
  before_action :find_notification, only: [:archive, :unarchive, :star]

  def index
    scope    = current_user.notifications

    scope = if params[:starred].present?
              scope.starred
            elsif params[:archive].present?
              scope.archived
            else
              scope.inbox
            end

    @types               = scope.distinct.group(:subject_type).count
    @statuses            = scope.distinct.group(:unread).count
    @reasons             = scope.distinct.group(:reason).count
    @unread_repositories = scope.distinct.group(:repository_full_name).count

    scope = scope.repo(params[:repo])     if params[:repo].present?
    scope = scope.reason(params[:reason]) if params[:reason].present?
    scope = scope.type(params[:type])     if params[:type].present?
    scope = scope.status(params[:status]) if params[:status].present?
    scope = scope.owner(params[:owner])   if params[:owner].present?

    @notifications = scope.newest.page(page).per(per_page)
  end

  def archive_selected
    current_user.notifications.where(id: params[:id]).update_all archived: params[:value]
    head :ok
  end

  def star
    @notification.update_columns starred: !@notification.starred?
    head :ok
  end

  def sync
    current_user.sync_notifications
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end

  private

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def render_home_page_unless_authenticated
    return render 'pages/home' unless logged_in?
  end

  def archive_params
    params.permit(:owner, :repo, :reason, :type, :status, :starred)
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
