# frozen_string_literal: true
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  test '#download fetches all read notification for a new user' do
    user = users(:newuser)
    all_notifications = notifications_from_fixture('newuser_all_notifications.json')
    unread_notifications = notifications_from_fixture('newuser_notifications.json')
    expected_attributes = build_expected_attributes(all_notifications)
    User.any_instance.stubs(:github_client).returns(mock {
      expects(:notifications).with(all: true, headers: {cache_control: ['no-store', 'no-cache']})
        .returns(all_notifications)
      expects(:notifications).with(headers: {cache_control: ['no-store', 'no-cache']}).returns(unread_notifications)
    })
    Notification.download(user)
    notifications = user.notifications.map(&:attributes)
    expected_attributes.each do |expected|
      assert attrs = notifications.select{|n| n['github_id'] == expected['github_id']}.first
      assert_equal attrs, attrs.merge(expected)
    end
  end

  test '#download fetches notifications newer than the oldest unread' do
    user = users(:userwithunread)
    # one second before oldest unread notification
    unread_since =( user.notifications.status(true).first.updated_at - 1).iso8601
    read_since =user.last_synced_at.iso8601
    User.any_instance.stubs(:github_client).returns(mock {
      expects(:notifications).with(headers: {cache_control: ['no-store', 'no-cache'], if_modified_since: read_since}).returns([])
      expects(:notifications).with(all: true, since: unread_since, headers: {cache_control: ['no-store', 'no-cache']}).returns([])
    })
    Notification.download(user)
  end

  test '#download will create new notification' do
    expected_attributes = build_expected_attributes(notifications_from_fixture('morty_notifications.json'))
    stub_notifications_request(body: file_fixture('morty_notifications.json'))
    user = users(:morty)
    user.notifications.destroy_all
    Notification.download(user)
    notifications = user.notifications.map(&:attributes)
    expected_attributes.each do |expected|
      assert attrs = notifications.select{|n| n['github_id'] == expected['github_id']}.first
      assert_equal attrs, attrs.merge(expected)
    end
  end

  test "#download will update and unarchive a notification" do
    expected_attributes =  build_expected_attributes(notifications_from_fixture('morty_notifications.json'))
                            .find{|n| n['github_id'] == 420}
    stub_notifications_request(body: file_fixture('morty_notifications.json'))
    user = users(:morty)
    notification = notifications(:morty_updated)
    assert notification.archived?
    refute notification.unread?
    Notification.download(user)
    notification.reload
    assert notification.unread?
    refute notification.archived?
    attrs = notification.attributes
    assert_equal attrs, attrs.merge(expected_attributes)
  end

  test "#download will set the url for a Repository invitation correctly" do
    stub_notifications_request(body: file_fixture('repository_invitation_notification.json'))
    user = users(:andrew)

    Notification.download(user)

    assert notification = Notification.last
    assert_equal 'RepositoryInvitation', notification.subject_type
    assert_match %r{https://github.com/.+/invitations$}, notification.subject_url
  end

  test '#download handles no new notifications' do
    Octokit::Client.any_instance.stubs(:notifications).returns('')
    user = users(:morty)
    Notification.download(user)
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

  def build_expected_attributes(expected_notifications, keys: nil)
    keys ||= DownloadService::API_ATTRIBUTE_MAP.keys
    expected_notifications.map{|n|
      notification = Notification.new
      notification.attributes = Notification.attributes_from_api_response(n)
      attrs = notification.attributes
      notification.destroy
      attrs.slice(*(keys.map(&:to_s)))
    }
  end

  def notifications_from_fixture(fixture_file)
    JSON.parse(file_fixture(fixture_file).read, object_class: OpenStruct).tap do |notifications|
      notifications.map { |n| n.last_read_at = Time.parse(n.last_read_at).to_s if n.last_read_at }
    end
  end
end
