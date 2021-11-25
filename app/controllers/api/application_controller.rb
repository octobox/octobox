class Api::ApplicationController < ApplicationController
  skip_forgery_protection

  def current_user
    @current_user ||= authenticate_with_http_token { |token, _| User.find_by(api_token: token) }
  end
end
