# frozen_string_literal: true
require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'will be redirected to sign in if not authenticated' do
    get '/'
    assert_redirected_to '/login'
  end

  test 'does not redirect if authenticated' do
    sign_in_as(users(:andrew))

    get '/'
    assert_response :success
  end
end
