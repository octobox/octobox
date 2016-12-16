class NotificationsController < ApplicationController
  def index
    @types = Notification.inbox.distinct.group(:subject_type).count
    @statuses = Notification.inbox.distinct.group(:unread).count
    @unread_repositories = Notification.inbox.distinct.group(:repository_full_name).count
    @read_repositories = Notification.distinct.pluck(:repository_full_name)
    if params[:archive].present?
      scope = Notification.archived.newest
    else
      scope = Notification.inbox.newest
    end
    scope = scope.repo(params[:repo]) if params[:repo].present?
    scope = scope.type(params[:type]) if params[:type].present?
    scope = scope.status(params[:status]) if params[:status].present?
    @notifications = scope
  end

  def archive
    notification = Notification.find(params[:id])
    notification.update_attributes(archived: true)
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end

  def sync
    Notification.download
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end
end
