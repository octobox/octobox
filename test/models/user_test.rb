# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    stub_user_request
    stub_notifications_request
  end

  test 'must have a github id' do
    user = users(:andrew)
    user.github_id = nil
    refute user.valid?
  end

  test 'must have a unique github_id' do
    user = User.create(github_id: users(:andrew), access_token: 'abcdefg')
    refute user.valid?
  end

  test 'must have an access_token' do
    user = users(:andrew)
    user.access_token = nil
    refute user.valid?
  end

  test 'must have a unique access_token' do
    user = User.create(github_id: 42, access_token: users(:andrew).access_token)
    refute user.valid?
  end

  test 'must have a github_login' do
    user = users(:andrew)
    user.github_login = nil
    refute user.valid?
  end

  test '#effective_access_token returns personal_access_token if it is defined' do
    user = User.create(github_id: 888, access_token: '12345', personal_access_token: '67890', github_login: 'foo')
    assert_equal user.effective_access_token, '67890'
  end

  test '#effective_access_token returns access_token if no personal_access_token is defined' do
    user = User.create(github_id: 999, access_token: '12345', github_login: 'foo')
    assert_equal user.effective_access_token, '12345'
  end

  test '.find_by_auth_hash finds a User by their github_id' do
    omniauth_config     = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid = users(:andrew).github_id
    assert_equal users(:andrew), User.find_by_auth_hash(omniauth_config)
  end

  test '#assign_from_auth_hash updates the users github_id and access_token' do
    user                              = users(:andrew)
    omniauth_config                   = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid               = 1
    omniauth_config.credentials.token = 'abcdefg'

    user.assign_from_auth_hash(omniauth_config)

    assert_equal 1, user.github_id
    assert_equal 'abcdefg', user.access_token
  end

  test 'does not allow a personal_access_token for another user' do
    stub_personal_access_tokens_enabled
    user = users(:andrew)
    user.personal_access_token = '1234'
    stub_user_request(body: '{"id": 98}')
    refute user.valid?
    assert_equal User::ERRORS[:invalid_token], user.errors.first
  end

  test 'does not allow a personal_access_token without the notifications scope' do
    stub_personal_access_tokens_enabled
    user = users(:andrew)
    user.personal_access_token = '1234'
    stub_user_request(oauth_scopes: 'user, repo')
    refute user.valid?
    assert_equal User::ERRORS[:missing_scope], user.errors.first
  end

  test 'does not allow setting personal_access_token without being enabled' do
    user = users(:andrew)
    user.personal_access_token = '1234'
    refute user.valid?
    assert_equal User::ERRORS[:disallowed_tokens], user.errors.first
  end

  test '#github_client returns an Octokit::Client with the correct access_token' do
    user = users(:andrew)
    assert_equal user.github_client.class, Octokit::Client
    assert_equal user.github_client.access_token, user.access_token
  end

  test '#github_client returns an Octokit::Client with the correct access_token after adding personal_access_token' do
    stub_personal_access_tokens_enabled
    user = users(:andrew)
    assert_equal user.github_client.class, Octokit::Client
    assert_equal user.access_token, user.github_client.access_token
    user.personal_access_token = '67890'
    user.save
    assert_equal '67890', user.github_client.access_token
  end

  test "triggers sync_notifications on save" do
    notifications_url = %r{https://api.github.com/notifications}

    body     = '[]'
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)

    User.create(github_id: 42, github_login: 'douglas_adams', access_token: 'abcdefg')

    assert_requested :get, notifications_url
  end
end
