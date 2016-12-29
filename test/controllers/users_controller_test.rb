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

end
