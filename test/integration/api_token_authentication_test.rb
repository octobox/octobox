require 'test_helper'

class ApiTokenAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test 'will get notifications if authenticated with api token' do
    get notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
  end

  test 'will get unauthorized if authenticated with wrong api token' do
    get notifications_path(format: :json), headers: { 'Authorization' => "Bearer NOPE" }
    assert_response :unauthorized
  end
end
