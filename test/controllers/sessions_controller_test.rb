# frozen_string_literal: true
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'GET #new redirects to /auth/github' do
    get '/login'
    assert_redirected_to '/auth/github'
  end

  test 'POST #create finds the GitHub user from the hash and redirects to the root_path' do
    OmniAuth.config.mock_auth[:github].uid = users(:andrew).github_id
    post '/auth/github/callback'

    assert_redirected_to root_path
  end

  test 'POST #create creates a GitHub user from the hash and redirects to the root_path' do
    notifications_url = %r{https://api.github.com/notifications}

    body     = '[]'
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)

    post '/auth/github/callback'

    assert User.find_by(github_id: OmniAuth.config.mock_auth[:github].uid)
    assert_redirected_to root_path
  end

  test 'GET #destroy redirects to /' do
    get '/logout'
    assert_redirected_to '/'
  end
end
