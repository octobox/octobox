# frozen_string_literal: true
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @omniauth_config = OmniAuth.config.mock_auth[:github]
    @omniauth_config.uid = users(:andrew)
  end

  test 'GET #new redirects to /auth/github' do
    get '/login'
    assert_redirected_to '/auth/github'
  end

  test 'POST #create finds the GitHub user and redirects to the root_path' do
    # post '/auth/github/callback', params: { uid: omniauth_config.uid }
    # assert_redirected_to root_path
  end
end
