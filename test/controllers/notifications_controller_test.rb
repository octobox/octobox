# frozen_string_literal: true
require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notifications_request
    @user = users(:andrew)
  end

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

  test 'archives a notification' do
    notification = create(:notification, user: @user, archived: false)

    sign_in_as(@user)

    get "/notifications/#{notification.id}/archive"
    assert_response :redirect

    assert notification.reload.archived?
  end

  test 'unarchives a notification' do
    notification = create(:notification, user: @user, archived: true)

    sign_in_as(@user)

    get "/notifications/#{notification.id}/unarchive"
    assert_response :redirect

    refute notification.reload.archived?
  end

  test 'toggles starred on a notification' do
    notification = create(:notification, user: @user, starred: false)

    sign_in_as(@user)

    get "/notifications/#{notification.id}/star"
    assert_response :ok

    assert notification.reload.starred?
  end

  test 'syncs users notifications' do
    sign_in_as(@user)

    post "/notifications/sync"
    assert_response :redirect
  end
end
