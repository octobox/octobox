# frozen_string_literal: true
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @notifications_request = stub_notifications_request(body: '[]') }

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
    post '/auth/github/callback'

    assert User.find_by(github_id: OmniAuth.config.mock_auth[:github].uid)
    assert_redirected_to root_path
  end

  test 'GET #destroy redirects to /' do
    get '/logout'
    assert_redirected_to '/'
  end

  test 'GET #failure redirects to / and sets a flash message' do
    get '/auth/failure'

    assert_redirected_to '/'
    assert_equal 'There was a problem authenticating with GitHub, please try again.', flash[:error]
  end
end
