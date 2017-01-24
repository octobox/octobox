# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    stub_user_request(user: @user)
    stub_notifications_request
  end

  def assert_error_present(model_object, error)
    refute model_object.valid?
    model_object.errors[error[0]].include? error[1]
  end

  test 'must have a github id' do
    @user.github_id = nil
    refute @user.valid?
  end

  test 'must have a unique github_id' do
    user = User.create(github_id: @user.github_id, access_token: 'abcdefg')
    refute user.valid?
  end

  test 'must have an access_token' do
    @user.access_token = nil
    refute @user.valid?
  end

  test 'must have a unique access_token' do
    user = User.create(github_id: 42, access_token: @user.access_token)
    refute user.valid?
  end

  test 'must have a github_login' do
    @user.github_login = nil
    refute @user.valid?
  end

  test '#effective_access_token returns personal_access_token if it is defined' do
    stub_personal_access_tokens_enabled
    user = build(:token_user)
    assert_equal user.personal_access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if personal_access_tokens_enabled? is false' do
    stub_personal_access_tokens_enabled(value: false)
    user = build(:token_user)
    assert_equal user.access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if no personal_access_token is defined' do
    stub_personal_access_tokens_enabled
    assert_equal @user.access_token, @user.effective_access_token
  end

  test '.find_by_auth_hash finds a User by their github_id' do
    omniauth_config     = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid = @user.github_id
    assert_equal @user, User.find_by_auth_hash(omniauth_config)
  end

  test '#assign_from_auth_hash updates the users github_id and access_token' do
    omniauth_config                   = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid               = 1
    omniauth_config.credentials.token = 'abcdefg'

    @user.assign_from_auth_hash(omniauth_config)

    assert_equal 1, @user.github_id
    assert_equal 'abcdefg', @user.access_token
  end

  test 'does not allow a personal_access_token for another user' do
    stub_personal_access_tokens_enabled
    @user.personal_access_token = '1234'
    stub_user_request(body: '{"id": 98}')
    assert_error_present(@user, User::ERRORS[:invalid_token])
  end

  test 'does not allow a personal_access_token without the notifications scope' do
    stub_personal_access_tokens_enabled
    @user.personal_access_token = '1234'
    stub_user_request(oauth_scopes: 'user, repo')
    assert_error_present(@user, User::ERRORS[:missing_scope])
  end

  test 'does not allow setting personal_access_token without being enabled' do
    stub_personal_access_tokens_enabled(value: false)
    @user.personal_access_token = '1234'
    assert_error_present(@user, User::ERRORS[:disallowed_tokens])
  end

  test '#github_client returns an Octokit::Client with the correct access_token' do
    assert_equal @user.github_client.class, Octokit::Client
    assert_equal @user.github_client.access_token, @user.access_token
  end

  test '#github_client returns an Octokit::Client with the correct access_token after adding personal_access_token' do
    stub_personal_access_tokens_enabled
    assert_equal @user.github_client.class, Octokit::Client
    assert_equal @user.access_token, @user.github_client.access_token
    @user.personal_access_token = '67890'
    stub_user_request(user: @user)
    @user.save
    assert_equal '67890', @user.github_client.access_token
  end

  test '#masked_personal_access_token returns empty string if personal_access_token is missing' do
    assert_equal @user.masked_personal_access_token, ''
  end

  test '#masked_personal_access_token returns stars with the last 8 chars of token' do
    @user.personal_access_token = 'abcdefghijklmnopqrstuvwxyz'
    assert_equal @user.masked_personal_access_token, '********************************stuvwxyz'
  end

  test 'rejects refresh_interval over a day' do
    @user.refresh_interval = 90_000_000
    refute @user.valid?
    assert_error_present(@user, User::ERRORS[:refresh_interval_size])
  end

  test 'rejects negative refresh_interval' do
    @user.refresh_interval = -90_000
    refute @user.valid?
    assert_error_present(@user, User::ERRORS[:refresh_interval_size])
  end

  test 'sets refresh interval' do
    @user.refresh_interval = 60_000
    @user.save
    assert_equal 60_000, @user.refresh_interval
  end

  [{refresh_interval: 90_000, minimum_refresh_interval: 0, expected_result: nil},
   {refresh_interval: 90_000, minimum_refresh_interval: 60, expected_result: 60 * 60_000},
   {refresh_interval: 0, minimum_refresh_interval: 60, expected_result: nil},
   {refresh_interval: 0, minimum_refresh_interval: 0, expected_result: nil}
  ].each do |t|
    test "effective_refresh_interval returns #{t[:expected_result]} when minimum_refresh_interval is #{t[:minimum_refresh_interval]} and refresh_interval is #{t[:refresh_interval]}" do
      stub_minimum_refresh_interval(t[:minimum_refresh_interval])
      @user.refresh_interval = t[:refresh_interval]
      @user.save
      if t[:expected_result].nil?
        assert_nil @user.effective_refresh_interval
      else
        assert_equal t[:expected_result], @user.effective_refresh_interval
      end
    end
  end

end
