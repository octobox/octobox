require 'test_helper'

class ApiUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_comments_requests
    @user = create(:user)
  end

  def create_token_user
    stub_personal_access_tokens_enabled
    stub_user_request(user: build(:token_user))
    @token_user = create(:token_user)
  end

  test 'gets profile as json' do
    create_token_user
    stub_user_request(user: @token_user, any_auth: true)
    get profile_api_users_path(format: :json), headers: { 'Authorization' => "Bearer #{@token_user.api_token}" }
    assert_template 'users/profile'
  end

  test 'will render 401 if authenticated via a cookie as json' do
    sign_in_as(@user)
    get profile_api_users_path(format: :json)
    assert_response :unauthorized
  end

  test 'updates api_token' do
    token = @user.api_token
    patch api_user_url(@user), params: {user: {regenerate_api_token: '1'}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    @user.reload
    assert_not_equal token, @user.api_token
  end

  test 'updates personal_access_token' do
    create_token_user
    stub_user_request(user: @token_user, any_auth: true)
    patch api_user_url(@token_user), params: {user: {personal_access_token: '12345'}}, headers: { 'Authorization' => "Bearer #{@token_user.api_token}" }
    @token_user.reload
    assert_equal '12345', @token_user.personal_access_token
  end

  test 'updates personal_access_token as json' do
    create_token_user
    stub_user_request(user: @token_user, any_auth: true)
    patch api_user_url(@token_user, format: :json), params: {user: {personal_access_token: '12345'}}, headers: { 'Authorization' => "Bearer #{@token_user.api_token}" }
    assert_response :ok
    @token_user.reload
    assert_equal '12345', @token_user.personal_access_token
  end

  test 'will not clear personal access token if clear_personal_access_token is not set' do
    create_token_user
    stub_user_request(user: @token_user)
    expected_token = @token_user.personal_access_token
    patch api_user_url(@token_user), params: {user: {personal_access_token: ' '}}, headers: { 'Authorization' => "Bearer #{@token_user.api_token}" }
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
  end

  test 'clears personal access token when clear_personal_access_token is set' do
    create_token_user
    stub_user_request(user: @token_user)
    patch api_user_url(@token_user), params: {user: {personal_access_token: 'asdf'}, clear_personal_access_token: 'on'}, headers: { 'Authorization' => "Bearer #{@token_user.api_token}" }
    @token_user.reload
    assert_nil @token_user.personal_access_token
  end

  test 'requires logged in user' do
    create_token_user
    stub_user_request(user: @token_user)
    expected_token = @token_user.personal_access_token
    patch api_user_url(@token_user), params: {user: {personal_access_token: '12345'}}
    assert_response :unauthorized
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
  end

  test 'rejects changing a different user' do
    create_token_user
    stub_user_request(user: @token_user)
    expected_token = @token_user.personal_access_token
    patch api_user_url(@token_user), params: {user: {personal_access_token: '12345'}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :unauthorized
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
    assert_nil @user.personal_access_token
  end

  test 'deletes a user' do
    delete api_user_url(@user), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
    refute User.exists?(@user.id)
  end

  test 'deletes a user as json' do
    delete api_user_url(@user, format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
    refute User.exists?(@user.id)
  end

  test 'cannot delete another user' do
    other_user = create(:user)
    delete api_user_url(@user), headers: { 'Authorization' => "Bearer #{other_user.api_token}" }
    assert_response :unauthorized
    assert User.exists?(@user.id)
    assert User.exists?(other_user.id)
  end

  test 'cannot delete user without logging in' do
    delete api_user_url(@user)
    assert_response :unauthorized
    assert User.exists?(@user.id)
  end

  test 'sets refresh_interval' do
    stub_user_request(user: @user)
    patch api_user_url(@user), params: {user: {refresh_interval: 12_345}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    @user.reload
    assert_equal 12_345, @user.refresh_interval
  end

  [{
     refresh_interval_minutes: 2,
     expected_refresh_interval: 120_000
   },
   {
     refresh_interval_minutes: '',
     expected_refresh_interval: nil
   },
   {
     refresh_interval_minutes: 1500,
     expected_refresh_interval: nil
   }].each do |t|
    test "sets refresh_interval to #{t[:expected_refresh_interval] || 'nil'} when refresh_interval_minutes is '#{t[:refresh_interval_minutes]}'" do
      patch api_user_url(@user), params: {user: {refresh_interval_minutes: t[:refresh_interval_minutes]}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
      @user.reload
      if t[:expected_refresh_interval].nil?
        assert_nil @user.refresh_interval
      else
        assert_equal t[:expected_refresh_interval], @user.refresh_interval
      end
    end
  end

  test 'rejects negative refresh_interval' do
    stub_user_request(user: @user)
    patch api_user_url(@user), params: {user: {refresh_interval: -60_000}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    @user.reload
    assert_nil @user.refresh_interval
  end

  test 'rejects negative refresh_interval as json' do
    stub_user_request(user: @user)
    patch api_user_url(@user, format: :json), params: {user: {refresh_interval: -60_000}}, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    @user.reload
    assert_nil @user.refresh_interval
    assert_response :unprocessable_content
  end
end
