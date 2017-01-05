# frozen_string_literal: true
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup { stub_notifications_request }

  test '#download fetches one months notification when a user has not been synched before' do
    travel_to "2016-12-19T19:00:00Z" do
      user = users(:andrew)
      user.last_synced_at = nil

      Notification.download(user)

      assert_requested :get, "https://api.github.com/notifications?all=true&per_page=100&since=2016-11-19T19:00:00Z"
    end
  end

  test '#download fetches one weeks notification when a user has synched before' do
    travel_to "2016-12-19T19:00:00Z" do
      user = users(:andrew)
      user.last_synced_at = "2016-12-19T19:00:00Z"

      Notification.download(user)

      assert_requested :get, "https://api.github.com/notifications?all=true&per_page=100&since=2016-12-12T19:00:00Z"
    end
  end

  test "#download will set the url for a Repository invitation correctly" do
    stub_notifications_request(body: file_fixture('repository_invitation_notification.json'))
    user = users(:andrew)

    Notification.download(user)

    assert notification = Notification.last
    assert_equal 'RepositoryInvitation', notification.subject_type
    assert_match %r{https://github.com/.+/invitations$}, notification.subject_url
  end

  test 'ignore_thread sends ignore request to github' do
    user = users(:andrew)
    notification = create(:notification, user: user, archived: false)
    user.stubs(:github_client).returns(mock {
      expects(:update_thread_subscription).with(notification.github_id, ignored: true).returns true
    })
    assert notification.ignore_thread
  end

  test 'mark_as_read updates the github thread' do
    user = users(:andrew)
    notification = create(:notification, user: user, archived: false)
    user.stubs(:github_client).returns(mock {
      expects(:mark_thread_as_read).with(notification.github_id, read: true).returns true
    })
    assert notification.mark_as_read
  end

  test 'mute ignores the thread and marks it as read' do
    user = users(:andrew)
    notification = create(:notification, user: user, archived: false)
    user.stubs(:github_client).returns(mock {
      expects(:update_thread_subscription).with(notification.github_id, ignored: true).returns true
      expects(:mark_thread_as_read).with(notification.github_id, read: true).returns true
    })
    assert notification.mute
  end
end
