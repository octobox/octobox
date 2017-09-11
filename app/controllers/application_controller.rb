# frozen_string_literal: true
class ApplicationController < ActionController::Base
  API_HEADER = 'X-Octobox-API'

  protect_from_forgery with: :exception, unless: -> { octobox_api_request? }
  helper_method :current_user, :logged_in?
  before_action :authenticate_user!

  private

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

  def octobox_api_request?
    request.headers[API_HEADER].present?
  end
end
