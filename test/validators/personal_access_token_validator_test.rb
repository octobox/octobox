# frozen_string_literal: true
require 'test_helper'

class PersonalAccessTokenValidatorTest < ActiveSupport::TestCase
  setup do
    @user = build(:user, personal_access_token: '1234')
    stub_user_request(user: @user)
    stub_personal_access_tokens_enabled
    stub_notifications_request
  end

  def assert_error_present(model_object, error)
    refute model_object.valid?
    assert model_object.errors[error[0]].include? error[1]
  end

  test 'it allows a blank personal_access_token' do
    @user.personal_access_token = nil
    assert @user.valid?
  end

  test 'does not allow setting personal_access_token without being enabled' do
    stub_personal_access_tokens_enabled(value: false)
    stub_user_request(user: @user, any_auth: true)
    assert_error_present(@user, PersonalAccessTokenValidator::ERRORS[:disallowed_tokens])
  end

  test 'does not allow invalid credentials' do
    Octokit::Client.any_instance.stubs(:validate_credentials).returns(false)
    stub_user_request(user: @user)
    assert_error_present(@user, PersonalAccessTokenValidator::ERRORS[:invalid_token])
  end

  test 'does not allow a personal_access_token for another user' do
    stub_user_request(body: '{"id": 98}')
    assert_error_present(@user, PersonalAccessTokenValidator::ERRORS[:invalid_token])
  end

  test 'does not allow a personal_access_token without the notifications scope' do
    stub_user_request(user: @user, oauth_scopes: 'user, repo')
    assert_error_present(@user, PersonalAccessTokenValidator::ERRORS[:missing_notifications_scope])
  end

  test 'does not allow a personal_access_token without the read:org scope if restricted_access enabled' do
    stub_restricted_access_enabled
    stub_user_request(oauth_scopes: 'user, repo')
    assert_error_present(@user, PersonalAccessTokenValidator::ERRORS[:missing_read_org_scope])
  end
end
