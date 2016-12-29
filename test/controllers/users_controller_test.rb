require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notifications_request
    stub_user_request
    @user = users(:andrew)
  end

  test 'should update user' do
    stub_personal_access_tokens_enabled
    sign_in_as(@user)
    patch user_url(@user), params: {user: { personal_access_token: '12345'}}
    @user.reload
    assert_equal '12345', @user.personal_access_token
  end

  test 'updates personal_access_token' do
    user = users(:tokenuser)
    stub_personal_access_tokens_enabled
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { personal_access_token: '12345'}}
    user.reload
    assert_equal '12345', user.personal_access_token
  end

  test 'will not clear personal access token if clear_personal_access_token is not set' do
    user = users(:tokenuser)
    stub_personal_access_tokens_enabled
    stub_user_request(user: user)
    sign_in_as(user)
    expected_token = user.personal_access_token
    patch user_url(user), params: {user: { personal_access_token: ' '}}
    user.reload
    assert_equal expected_token, user.personal_access_token
  end

  test 'clears personal access token when clear_personal_access_token is set' do
    user = users(:tokenuser)
    stub_personal_access_tokens_enabled
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { personal_access_token: 'asdf'}, clear_personal_access_token: 'on'}
    user.reload
    assert_nil user.personal_access_token
  end

end
