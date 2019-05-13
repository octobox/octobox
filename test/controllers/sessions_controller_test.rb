# frozen_string_literal: true
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Octobox.config.stubs(:github_app).returns(false)
    @notifications_request = stub_notifications_request(body: '[]')
    @user = create(:user)
  end

  test 'authenticated users without access tokens are logged out' do
    sign_in_as(@user)
    @user.access_token = nil
    @user.save(validate: false) # Requires access token

    get '/settings'
    assert_redirected_to login_path
  end

  test 'GET #new redirects to /auth/github' do
    get '/login'
    assert_redirected_to '/auth/github'
  end

  test 'GET #new redirects to /root if already logged in' do
    sign_in_as(@user)
    get '/login'
    assert_redirected_to '/'
  end

  test 'POST #create finds the GitHub user from the hash and redirects to the root_path' do
    OmniAuth.config.mock_auth[:github].uid = @user.github_id
    post '/auth/github/callback'

    assert_redirected_to root_path
  end

  test 'POST #create creates a GitHub user from the hash and redirects to the root_path' do
    post '/auth/github/callback'

    assert User.find_by(github_id: OmniAuth.config.mock_auth[:github].uid)
    assert_redirected_to root_path
  end

  test 'POST #create forces the user to sync their notifications if they have synced before' do
    OmniAuth.config.mock_auth[:github].uid = @user.github_id

    post '/auth/github/callback'
    assert_equal 1, SyncNotificationsWorker.jobs.size
  end

  test 'POST #create redirects to the root_path with an error message if they are not an org member' do
    OmniAuth.config.mock_auth[:github].uid           = @user.github_id
    OmniAuth.config.mock_auth[:github].info.nickname = @user.github_login

    stub_restricted_access_enabled
    stub_env_var('GITHUB_ORGANIZATION_ID', 1)
    stub_organization_membership_request(organization_id: 1, user: @user.github_login, successful: false)

    post '/auth/github/callback'
    assert_redirected_to root_path
    assert_equal 'Access denied.', flash[:error]
  end

  test 'POST #create redirects to the root_path with an error message if they are not an team member' do
    OmniAuth.config.mock_auth[:github].uid           = @user.github_id
    OmniAuth.config.mock_auth[:github].info.nickname = @user.github_login

    stub_restricted_access_enabled
    stub_env_var('GITHUB_TEAM_ID', 1)
    stub_team_membership_request(team_id: 1, user: @user.github_login, successful: false)

    post '/auth/github/callback'
    assert_redirected_to root_path
    assert_equal 'Access denied.', flash[:error]
  end

  test 'POST #create is successful if the user is an org member' do
    OmniAuth.config.mock_auth[:github].uid           = @user.github_id
    OmniAuth.config.mock_auth[:github].info.nickname = @user.github_login

    stub_restricted_access_enabled
    stub_env_var('GITHUB_ORGANIZATION_ID', 1)
    stub_organization_membership_request(organization_id: 1, user: @user.github_login, successful: true)

    post '/auth/github/callback'
    assert_redirected_to root_path
    assert_nil flash[:error]
  end

  test 'POST #create is successful if the user is a team member' do
    OmniAuth.config.mock_auth[:github].uid           = @user.github_id
    OmniAuth.config.mock_auth[:github].info.nickname = @user.github_login

    stub_restricted_access_enabled
    stub_env_var('GITHUB_TEAM_ID', 1)
    stub_team_membership_request(team_id: 1, user: @user.github_login, successful: true)

    post '/auth/github/callback'
    assert_redirected_to root_path
    assert_nil flash[:error]
  end

  test 'GET #destroy redirects to /' do
    cookies['user_id'] = 1
    get '/logout'
    assert_redirected_to '/'
    assert_empty cookies['user_id']
  end

  test 'GET #failure redirects to / and sets a flash message' do
    get '/auth/failure'

    assert_redirected_to '/'
    assert_equal 'There was a problem authenticating with GitHub, please try again.', flash[:error]
  end
end
