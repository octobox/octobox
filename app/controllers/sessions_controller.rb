# frozen_string_literal: true
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to '/auth/github'
  end

  def create
    auth_hash = request.env['omniauth.auth']
    user      = User.find_by_auth_hash(auth_hash) || User.new

    user.assign_from_auth_hash(auth_hash)

    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  def failure
    flash[:error] = 'There was a problem authenticating with GitHub, please try again.'
    redirect_to root_path
  end
end
