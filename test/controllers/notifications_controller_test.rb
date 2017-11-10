# frozen_string_literal: true
require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notifications_request
    @user = create(:user)
  end

  test 'will render the home page if not authenticated' do
    get '/'
    assert_response :success
    assert_template 'pages/home'
  end

  test 'will render 401 if not authenticated as json' do
    get notifications_path(format: :json)
    assert_response :unauthorized
  end

  test 'will render 404 if not json' do
    sign_in_as(@user)
    assert_raises ActionController::UrlGenerationError do
      get notifications_path
    end
  end

  test 'renders the index page if authenticated' do
    sign_in_as(@user)

    get '/'
    assert_response :success
    assert_template 'notifications/index', file: 'notifications/index.html.erb'
  end

  test 'renders the index page as json if authenticated' do
    sign_in_as(@user)

    get notifications_path(format: :json)
    assert_response :success
    assert_template 'notifications/index', file: 'notifications/index.json.jbuilder'
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

  test 'shows archived search results by default' do
    sign_in_as(@user)
    5.times.each { create(:notification, user: @user, archived: true, subject_title:'release-1') }
    get '/?q=release'
    assert_equal assigns(:notifications).length, 5
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

  test 'redirect back to last page of results if page is out of bounds and send filters' do
    sign_in_as(@user)
    25.times.each { create(:notification, user: @user, archived: false, unread: true) }

    get '/?page=3&reason=subscribed&unread=true'
    assert_redirected_to '/?page=2&reason=subscribed&unread=true'
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

  test 'archives all notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    post '/notifications/archive_selected', params: { id: ['all'], value: true }

    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
    assert notification3.reload.archived?
  end

  test 'archives respects current filters' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false, unread: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    post '/notifications/archive_selected', params: { unread: true, id: ['all'], value: true }

    assert_response :ok

    refute notification1.reload.archived?
    assert notification2.reload.archived?
    assert notification3.reload.archived?
  end


  test 'mutes multiple notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mute).with([notification1, notification2])

    post '/notifications/mute_selected', params: { id: [notification1.id, notification2.id] }
    assert_response :ok
  end

  test 'mutes all notifications in current scope' do
    sign_in_as(@user)
    Notification.destroy_all
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mute).with([notification1, notification2, notification3])

    post '/notifications/mute_selected', params: { id: ['all'] }
    assert_response :ok
  end

  test 'marks read multiple notifications' do
    sign_in_as(@user)
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mark_read).with([notification1, notification2])

    post '/notifications/mark_read_selected', params: { id: [notification1.id, notification2.id] }
    assert_response :ok
  end

  test 'marks read all notifications' do
    sign_in_as(@user)
    Notification.destroy_all
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mark_read).with([notification1, notification2, notification3])

    post '/notifications/mark_read_selected', params: { id: ['all'] }
    assert_response :ok
  end

  test 'toggles starred on a notification' do
    notification = create(:notification, user: @user, starred: false)

    sign_in_as(@user)

    post "/notifications/#{notification.id}/star"
    assert_response :ok

    assert notification.reload.starred?
  end

  test 'toggles unread on a notification' do
    notification = create(:notification, user: @user, unread: true)

    sign_in_as(@user)

    post "/notifications/#{notification.id}/mark_read"
    assert_response :ok

    refute notification.reload.unread?
  end

  test 'syncs users notifications' do
    sign_in_as(@user)

    post "/notifications/sync"
    assert_response :redirect
  end

  test 'syncs users notifications as json' do
    sign_in_as(@user)

    post "/notifications/sync.json"
    assert_response :ok
  end

  test 'gracefully handles failed user notification syncs' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Octokit::BadGateway)

    post "/notifications/sync"
    assert_response :redirect
    assert_equal "Having issues connecting to GitHub. Please try again.", flash[:error]
  end

  test 'gracefully handles failed user notification syncs as json' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Octokit::BadGateway)

    post "/notifications/sync.json"
    assert_response :service_unavailable
  end

  test 'gracefully handles failed user notification syncs with wrong token' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Octokit::Unauthorized)

    post "/notifications/sync"
    assert_response :redirect
    assert_equal "Your GitHub token seems to be invalid. Please try again.", flash[:error]
  end

  test 'gracefully handles forbidden user notification syncs' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Octokit::Forbidden)

    post "/notifications/sync"
    assert_response :redirect
    assert_equal "Your GitHub token seems to be invalid. Please try again.", flash[:error]
  end

  test 'gracefully handles failed user notification syncs with bad token as json' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Octokit::Unauthorized)

    post "/notifications/sync.json"
    assert_response :service_unavailable
  end

  test 'gracefully handles failed user notification syncs when user is offline' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Faraday::ConnectionFailed.new('offline error'))

    post "/notifications/sync"
    assert_response :redirect
    assert_equal "You seem to be offline. Please try again.", flash[:error]
  end

  test 'gracefully handles failed user notification syncs when user is offline as json' do
    sign_in_as(@user)
    User.any_instance.stubs(:sync_notifications).raises(Faraday::ConnectionFailed.new('offline error'))

    post "/notifications/sync.json"
    assert_response :service_unavailable
  end

  test 'renders the inbox notifcation count in the sidebar' do
    sign_in_as(@user)
    create(:notification, user: @user, archived: false)
    create(:notification, user: @user, archived: false)
    create(:notification, user: @user, archived: false)

    create(:notification, user: @user, archived: true)
    create(:notification, user: @user, archived: true)

    create(:notification, user: @user, starred: true)
    create(:notification, user: @user, starred: true)
    create(:notification, user: @user, starred: true)

    get '/'
    assert_response :success

    assert_select("li[role='presentation'] > a > span") do |elements|
      assert_equal elements[0].text, '7'
    end
  end

  test 'renders pagination info for notifications in json' do
    sign_in_as(@user)

    get notifications_path(format: :json)

    assert_response :success
    json = JSON.parse(response.body)
    notification_count = Notification.inbox.where(user: @user).count
    assert_equal notification_count, json["pagination"]["total_notifications"]
    assert_equal 0, json["pagination"]["page"]
    assert_equal (notification_count.to_f / 20).ceil, json["pagination"]["total_pages"]
    assert_equal [notification_count, 20].min, json["pagination"]["per_page"]
  end

  test 'renders pagination info for zero notifications in json' do
    sign_in_as(@user)
    Notification.destroy_all

    get notifications_path(format: :json)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 0, json["pagination"]["total_notifications"]
    assert_equal 0, json["pagination"]["page"]
    assert_equal 0, json["pagination"]["total_pages"]
    assert_equal 0, json["pagination"]["per_page"]
  end
  
  test 'renders a union of notifications when multiple reasons given' do
    sign_in_as(@user)
    Notification.destroy_all
    
    notification1 = create(:notification, user: @user, archived: false, reason: "assign")
    notification2 = create(:notification, user: @user, archived: false, reason: "mention")
    notification3 = create(:notification, user: @user, archived: false, reason: "subscribed")
    
    get notifications_path(format: :json, reason: "assign,mention")
    
    assert_response :success
    
    json = JSON.parse(response.body)
    notification_ids = json["notifications"].map { |n| n["id"] }

    assert notification_ids.include?(notification1.id)
    assert notification_ids.include?(notification2.id)
    refute notification_ids.include?(notification3.id)
  end
end
