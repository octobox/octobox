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

  test 'renders the starred page' do
    sign_in_as(@user)

    get '/?starred=true'
    assert_response :success
    assert_template 'notifications/index'
  end

  test 'renders the archive page' do
    sign_in_as(@user)

    get '/?archive=true'
    assert_response :success
    assert_template 'notifications/index'
  end

  test 'shows only 20 notifications per page' do
    sign_in_as(@user)
    25.times.each { create(:notification, user: @user, archived: false) }

    get '/'
    assert_equal assigns(:notifications).length, 20
  end

  test 'redirect back to last page of results if page is out of bounds' do
    sign_in_as(@user)
    25.times.each { create(:notification, user: @user, archived: false) }

    get '/?page=3'
    assert_redirected_to '/?page=2'
  end

  test 'archives multiple notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    post '/notifications/archive_selected', params: { id: [notification1.id, notification2.id], value: true }

    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
    refute notification3.reload.archived?
  end

  test 'mutes multiple notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)
    User.any_instance.stubs(:github_client).returns(mock {
      expects(:update_thread_subscription).with(notification1.github_id, ignored: true).returns true
      expects(:update_thread_subscription).with(notification2.github_id, ignored: true).returns true
      expects(:mark_thread_as_read).with(notification1.github_id, read: true).returns true
      expects(:mark_thread_as_read).with(notification2.github_id, read: true).returns true
    })
    post '/notifications/mute_selected', params: { id: [notification1.id, notification2.id] }
    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
    refute notification3.reload.archived?
  end

  test 'marks read multiple notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)
    User.any_instance.stubs(:github_client).returns(mock {
      expects(:mark_thread_as_read).with(notification1.github_id, read: true).returns true
      expects(:mark_thread_as_read).with(notification2.github_id, read: true).returns true
    })
    post '/notifications/mark_read_selected', params: { id: [notification1.id, notification2.id] }
    assert_response :ok

    refute notification1.reload.unread?
    refute notification2.reload.unread?
    assert notification3.reload.unread?
  end

  test 'toggles starred on a notification' do
    notification = create(:notification, user: @user, starred: false)

    sign_in_as(@user)

    get "/notifications/#{notification.id}/star"
    assert_response :ok

    assert notification.reload.starred?
  end

  test 'toggles unread on a notification' do
    notification = create(:notification, user: @user, unread: true)

    sign_in_as(@user)

    get "/notifications/#{notification.id}/mark_as_read"
    assert_response :ok

    refute notification.reload.unread?
  end

  test 'syncs users notifications' do
    sign_in_as(@user)

    post "/notifications/sync"
    assert_response :redirect
  end
end
