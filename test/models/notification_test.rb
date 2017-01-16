# frozen_string_literal: true
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  include NotificationTestHelper

  test 'ignore_thread sends ignore request to github' do
    user = users(:andrew)
    notification = create(:notification, user: user, archived: false)
    user.stubs(:github_client).returns(mock {
      expects(:update_thread_subscription).with(notification.github_id, ignored: true).returns true
    })
    assert notification.ignore_thread
  end

  test 'mark_as_read updates the github thread' do
    notification = notifications(:unreadone)
    notification.user.stubs(:github_client).returns(mock {
      expects(:mark_thread_as_read).with(notification.github_id, read: true).returns true
    })
    notification.mark_as_read(update_github: true)
    refute notification.reload.unread?
  end

  test 'mark_as_read does not change updated_at' do
    notification = notifications(:unreadone)
    expected_updated_at = notification.updated_at
    notification.mark_as_read
    assert_equal expected_updated_at, notification.reload.updated_at
  end

  test 'mark_as_read turns unread to false' do
    notification = notifications(:unreadone)
    notification.mark_as_read
    refute notification.reload.unread?
  end

  test 'mark_as_read does not update github when update_github:false' do
    # the real assertion here is that no http request is made
    notifications(:unreadone).mark_as_read
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

  test 'unarchive_if_updated unarchives when updated_at is newer' do
    notification = notifications(:archived)
    notification.updated_at += 1
    notification.unarchive_if_updated
    refute notification.archived?
  end

  test 'unarchive_if_updated does nothing when updated_at is older' do
    notification = notifications(:archived)
    notification.updated_at -= 1
    notification.unarchive_if_updated
    assert notification.archived?
  end

  test 'unarchive_if_updated does nothing unless updated_at is changed' do
    notification = notifications(:archived)
    notification.subject_title = "whatever"
    notification.unarchive_if_updated
    assert notification.archived?
  end

  test 'unarchive_if_updated does nothing if nothing is changed' do
    notification = notifications(:archived)
    notification.unarchive_if_updated
    assert notification.archived?
  end

  test 'update_from_api_response updates attributes' do
    api_response = notifications_from_fixture('morty_notifications.json').first
    notification = notifications(:morty_updated)
    expected_attributes = notification.attributes.merge(
      {last_read_at: '2016-12-19 22:01:45 UTC',
       updated_at: Time.zone.parse('2016-12-19T22:01:45Z'),
       unread: true,
       archived: false}.stringify_keys)
    notification.update_from_api_response(api_response, unarchive: true)
    assert notification.unread?
    refute notification.archived?
    assert_equal expected_attributes, notification.attributes
  end

  test 'update_from_api_response updates attributes on a new notification' do
    user = users(:morty)
    expected_attributes = {
      user_id: user.id,
      github_id: 421,
      repository_id: 930405,
      repository_full_name: 'octobox/octobox',
      subject_title: 'More stuff',
      subject_url: 'https://api.github.com/repos/octobox/octobox/issues/560',
      subject_type: 'Issue',
      reason: 'subscribed',
      unread: true,
      last_read_at: nil,
      url: 'https://api.github.com/notifications/threads/421',
      archived: false,
      starred: false,
      repository_owner_name: 'andrew',
      updated_at: Time.zone.parse('2016-12-19T22:00:00Z')
    }.stringify_keys
    api_response = notifications_from_fixture('morty_notifications.json').second
    n = user.notifications.find_or_initialize_by(github_id: api_response[:id])
    n.update_from_api_response(api_response, unarchive: true)
    attributes = n.attributes
    assert_equal attributes, attributes.merge(expected_attributes)
  end
end
