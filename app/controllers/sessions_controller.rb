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

    client = Octokit::Client.new(access_token: auth_hash.credentials.token, auto_paginate: true)
    return true if organization_member?(client) || team_member?(client)

    flash[:error] = 'Access denied.'
    redirect_to root_path
  end

  def organization_member?(client)
    org_id = Octobox.config.github_organization_id
    return false unless org_id

    orgs = client.organizations(headers: { 'Cache-Control' => 'no-cache, no-store' })
    return false unless orgs

    orgs.any? { |org| org['id'].to_i == org_id }
  end

  def team_member?(client)
    team_id = Octobox.config.github_team_id
    return false unless team_id

    teams = client.user_teams(headers: { 'Cache-Control' => 'no-cache, no-store' })
    return false unless teams

    teams.any? { |team| team['id'].to_i == team_id }
  end
end
