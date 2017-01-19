# frozen_string_literal: true
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authorize_access!, only: :create

  def new
    redirect_to '/auth/github'
  end

  def create
    user = User.find_by_auth_hash(auth_hash) || User.new

    user.assign_from_auth_hash(auth_hash)
    user.sync_notifications

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

  private

  def auth_hash
    @auth_hash ||= request.env['omniauth.auth']
  end

  def authorize_access!
    return true unless Octobox.restricted_access_enabled?

    client = Octokit::Client.new(access_token: auth_hash.credentials.token)
    nickname = auth_hash.info.nickname

    return true if organization_member?(client, nickname) || team_member?(client, nickname)

    flash[:error] = 'Access denied.'
    redirect_to root_path
  end

  def organization_member?(*args)
    member?(*args, type: :organization)
  end

  def team_member?(*args)
    member?(*args, type: :team)
  end

  def member?(client, nickname, type:)
    id = ENV["GITHUB_#{type.to_s.upcase}_ID"]
    return false unless id.present?

    begin
      client.public_send("#{type}_member?",
        id.to_i,
        nickname,
        headers: { 'Cache-Control' => 'no-cache, no-store' }
      )
    rescue Octokit::Error
      false
    end
  end
end
