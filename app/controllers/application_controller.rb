# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
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
    return nil unless cookies.permanent.signed[:user_id].present?
    @current_user ||= User.find_by(id: cookies.permanent.signed[:user_id])
  end

  def logged_in?
    !current_user.nil?
  end
end
