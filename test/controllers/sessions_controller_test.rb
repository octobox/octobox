# frozen_string_literal: true
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'GET #new redirects to /auth/github' do
    get '/login'
    assert_redirected_to '/auth/github'
  end

  test 'POST #create finds the GitHub user from the hash and redirects to the root_path' do
    post '/auth/github/callback', env: { 'omniauth' => session_user_hash(users(:andrew)) }
    assert_redirected_to root_path
  end

  test 'POST #create creates a GitHub user from the hash and redirects to the root_path' do
    user = users(:andrew)

    User.destroy_all
    assert_equal 0, User.count

    post '/auth/github/callback', env: { 'omniauth' => session_user_hash(user) }

    assert_equal User.count, 1
    assert User.find_by(github_id: user.github_id)
    assert_redirected_to root_path
  end

  private

  def session_user_hash(user)
    hash = OmniAuth.config.mock_auth[:github].to_h
    hash.tap do |h|
      h['uid'] = user.github_id
      h['credentials'] = OmniAuth.config.mock_auth[:github].credientials.to_h
      h['credentials']['token'] = user.access_token
    end
  end
end
