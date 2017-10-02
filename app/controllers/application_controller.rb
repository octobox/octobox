# frozen_string_literal: true
class ApplicationController < ActionController::Base
  API_HEADER = 'X-Octobox-API'

  protect_from_forgery with: :exception, unless: -> { octobox_api_request? }
  helper_method :current_user, :logged_in?, :initial_sync?
  before_action :authenticate_user!

  before_bugsnag_notify :add_user_info_to_bugsnag if Rails.env.production?

  rescue_from Octokit::Unauthorized, Octokit::Forbidden do |exception|
    handle_exception(exception, :service_unavailable, I18n.t("exceptions.octokit.unauthorized"))
  end
  rescue_from Octokit::BadGateway, Octokit::ServiceUnavailable do |exception|
    handle_exception(exception, :service_unavailable, I18n.t("exceptions.octokit.unavailable"))
  end
  rescue_from Faraday::ClientError do |exception|
    handle_exception(exception, :service_unavailable, I18n.t("exceptions.faraday.connection_failed"))
  end

  private

  def add_user_info_to_bugsnag(notification)
    return unless logged_in?

    notification.user = {
      id: current_user.id,
      login: current_user.github_login
    }
  end

  def authenticate_user!
    return if logged_in?
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def current_user
    user_id = cookies.permanent.signed[:user_id]
    return nil unless user_id.present?
    @current_user ||= User.find_by(id: user_id)
  end

  def logged_in?
    !current_user.nil?
  end

  def initial_sync?
    current_user.last_synced_at.nil?
  end

  def octobox_api_request?
    request.headers[API_HEADER].present?
  end

  def handle_exception(exception, status, message='')
    logger.error("[ERROR] #{controller_name}##{action_name} \
                 #{current_user.try(:github_login)} - #{exception.class}: #{exception.message}")

    flash[:error] = "#{message}. Please try again."

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.json { head status }
    end
  end
end
