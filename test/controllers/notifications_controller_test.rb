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

  test 'archives all notifications' do
    user = users(:andrew)
    5.times.each { create(:notification, user: user, archived: false) }

    sign_in_as(user)

    post '/notifications/archive'
    assert_response :redirect

    user.notifications.each do |n|
      assert_equal n.archived, true
    end
  end

  test 'shows only 20 notifications per page' do
    user = users(:andrew)
    sign_in_as(user)
    25.times.each { create(:notification, user: user, archived: false) }

    get '/'
    assert_equal assigns(:notifications).length, 20
  end
end
