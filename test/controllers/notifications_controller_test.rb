# frozen_string_literal: true
require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'will render the home page if not authenticated' do
    get '/'
    assert_response :success
    assert_template 'pages/home'
  end

  test 'renders the index page if authenticated' do
    sign_in_as(users(:andrew))

    get '/'
    assert_response :success
    assert_template 'notifications/index'
  end
end
