class Api::ApplicationController < ApplicationController
  protect_from_forgery with: :null_session

  def current_user
    @current_user ||= authenticate_with_http_token { |token, _| User.find_by(api_token: token) }
  end
end
