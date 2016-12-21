# frozen_string_literal: true
require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:andrew) }

  test 'will render the home page if not authenticated' do
    get '/'
    assert_response :success
    assert_template 'pages/home'
  end

  test 'renders the index page if authenticated' do
    sign_in_as(@user)

    get '/'
    assert_response :success
    assert_template 'notifications/index'
  end

  test 'archives all notifications' do
    5.times.each { create(:notification, user: @user, archived: false) }

    sign_in_as(@user)

    post '/notifications/archive'
    assert_response :redirect

    @user.notifications.each { |n| assert n.archived? }
  end

  test 'archives all scoped notifications' do
    pull_request_notification = create(:notification, user: @user, subject_type: 'PullRequest')
    issue_notification        = create(:notification, user: @user, subject_type: 'Issue')

    sign_in_as(@user)

    post '/notifications/archive', params: { type: 'PullRequest' }
    assert_response :redirect

    assert pull_request_notification.reload.archived?
    refute issue_notification.reload.archived?
  end

  test 'shows only 20 notifications per page' do
    sign_in_as(@user)
    25.times.each { create(:notification, user: @user, archived: false) }

    get '/'
    assert_equal assigns(:notifications).length, 20
  end
end
