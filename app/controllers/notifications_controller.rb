# frozen_string_literal: true
class NotificationsController < ApplicationController
  def index
    scope = current_user.notifications
    scope = params[:archive].present? ? scope.archived : scope.inbox

    @types               = scope.distinct.group(:subject_type).count
    @statuses            = scope.distinct.group(:unread).count
    @reasons             = scope.distinct.group(:reason).count
    @unread_repositories = scope.distinct.group(:repository_full_name).count
    @starred             = scope.starred.count

    scope = scope.repo(params[:repo])     if params[:repo].present?
    scope = scope.reason(params[:reason]) if params[:reason].present?
    scope = scope.type(params[:type])     if params[:type].present?
    scope = scope.status(params[:status]) if params[:status].present?
    scope = scope.starred                 if params[:starred].present?

    @notifications = scope.newest
  end

  def archive
    notification = current_user.notifications.find(params[:id])
    notification.update_attributes(archived: true)

    redirect_to root_path(type: params[:type], repo: params[:repo])
  end

  def unarchive
    notification = Notification.find(params[:id])
    notification.update_attributes(archived: false)
    redirect_to root_path(type: params[:type], repo: params[:repo], archive: true)
  end

  def star
    notification = current_user.notifications.find(params[:id])
    starred = notification.starred?
    notification.update_attributes(starred: !starred)
    head :ok
  end

  def sync
    Notification.download(current_user)
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end
end
