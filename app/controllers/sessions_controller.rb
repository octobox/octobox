# frozen_string_literal: true
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_access_token_present
  before_action :authorize_access!, only: :create

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by_auth_hash(auth_hash) || User.new
    user.assign_from_auth_hash(auth_hash, params[:provider])

    cookies.permanent.signed[:user_id] = {value: user.id, httponly: true}

    user.sync_notifications unless initial_sync?
    redirect_to request.env['omniauth.origin'] || root_path
  end

  def destroy
    cookies.delete :user_id
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
    return true if organization_member?(client, user: nickname) || team_member?(client, user: nickname)

    flash[:error] = 'Access denied.'
    redirect_to root_path
  end

  def organization_member?(client, user:)
    org_id = Octobox.config.github_organization_id
    return false unless org_id
    member?(client, method_name: :organization_member, id: org_id, user: user)
  end

  def team_member?(client, user:)
    team_id = Octobox.config.github_team_id
    return false unless team_id
    member?(client, method_name: :team_member, id: team_id, user: user)
  end

  def member?(client, method_name:, id:, user:)
    case method_name
    when :team_member
      client.team_member?(id, user, headers: { 'Cache-Control' => 'no-cache, no-store' })
    when :organization_member
      client.organization_member?(id, user, headers: { 'Cache-Control' => 'no-cache, no-store' })
    else
      raise "#{method_name} is not a valid check for member?"
    end
  end
end
