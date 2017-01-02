# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    stub_user_request
    stub_notifications_request
  end

  def assert_error_present(model_object, error)
    refute model_object.valid?
    model_object.errors[error[0]].include? error[1]
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
    stub_personal_access_tokens_enabled
    user = users(:tokenuser)
    assert_equal user.personal_access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if personal_access_tokens_enabled? is false' do
    user = users(:tokenuser)
    assert_equal user.access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if no personal_access_token is defined' do
    stub_personal_access_tokens_enabled
    user = users(:andrew)
    assert_equal user.access_token, user.effective_access_token
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
    assert_error_present(user, User::ERRORS[:invalid_token])
  end

  test 'does not allow a personal_access_token without the notifications scope' do
    stub_personal_access_tokens_enabled
    user = users(:andrew)
    user.personal_access_token = '1234'
    stub_user_request(oauth_scopes: 'user, repo')
    assert_error_present(user, User::ERRORS[:missing_scope])
  end

  test 'does not allow setting personal_access_token without being enabled' do
    user = users(:andrew)
    user.personal_access_token = '1234'
    assert_error_present(user, User::ERRORS[:disallowed_tokens])
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

  test '#masked_personal_access_token returns empty string if personal_access_token is missing' do
    user = users(:andrew)
    assert_equal user.masked_personal_access_token, ''
  end

  test '#masked_personal_access_token returns stars with the last 8 chars of token' do
    user = users(:andrew)
    user.personal_access_token = 'abcdefghijklmnopqrstuvwxyz'
    assert_equal user.masked_personal_access_token, '********************************stuvwxyz'
  end
end
