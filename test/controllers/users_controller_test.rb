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

  test 'requires logged in user' do
    user = users(:tokenuser)
    stub_personal_access_tokens_enabled
    stub_user_request(user: user)
    expected_token = user.personal_access_token
    patch user_url(user), params: {user: { personal_access_token: '12345'}}
    assert_redirected_to root_path
    user.reload
    assert_equal expected_token, user.personal_access_token
  end

  test 'rejects changing a different user' do
    user = users(:tokenuser)
    stub_personal_access_tokens_enabled
    stub_user_request(user: user)
    sign_in_as(users(:andrew))
    expected_token = user.personal_access_token
    patch user_url(user), params: {user: { personal_access_token: '12345'}}
    assert_response :unauthorized
    user.reload
    assert_equal expected_token, user.personal_access_token
    assert_nil users(:andrew).personal_access_token
  end

  test 'deletes a user' do
    sign_in_as(users(:andrew))
    delete user_url(users(:andrew))
    assert_redirected_to root_path
    assert_equal "User deleted: #{users(:andrew).github_login}", flash[:success]
    refute User.exists?(users(:andrew).id)
  end

  test 'cannot delete another user' do
    sign_in_as(users(:tokenuser))
    delete user_url(users(:andrew))
    assert_response :unauthorized
    assert User.exists?(users(:andrew).id)
    assert User.exists?(users(:tokenuser).id)
  end

  test 'cannot delete user without logging in' do
    delete user_url(users(:andrew))
    assert_redirected_to root_path
    assert User.exists?(users(:andrew).id)
  end

  test 'sets refresh_interval' do
    user = users(:andrew)
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { refresh_interval: 12_345}}
    user.reload
    assert_equal 12_345, user.refresh_interval
  end

  test 'sets refresh_interval from minutes' do
    user = users(:andrew)
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { refresh_interval_minutes: 2}}
    user.reload
    assert_equal 120_000, user.refresh_interval
  end

  test 'rejects refresh_interval > 1 day' do
    user = users(:andrew)
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { refresh_interval_minutes: 1500}}
    user.reload
    assert_equal 0, user.refresh_interval
  end

  test 'rejects negative refresh_interval' do
    user = users(:andrew)
    stub_user_request(user: user)
    sign_in_as(user)
    patch user_url(user), params: {user: { refresh_interval: -60_000}}
    user.reload
    assert_equal 0, user.refresh_interval
  end


  test 'updates sync_on_load' do
    refute @user.sync_on_load
    sign_in_as(@user)
    patch user_url(@user), params: {user: { sync_on_load: '1'}}
    @user.reload
    assert @user.sync_on_load
    patch user_url(@user), params: {user: { sync_on_load: '0'}}
    @user.reload
    refute @user.sync_on_load
  end
end
