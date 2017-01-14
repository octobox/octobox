# frozen_string_literal: true
require 'test_helper'

class DownloadServiceTest < ActiveSupport::TestCase
  include NotificationTestHelper

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
    user.download_service.download
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
    user.download_service.download
  end

  test '#download will create new notification' do
    expected_attributes = build_expected_attributes(notifications_from_fixture('morty_notifications.json'))
    stub_notifications_request(body: file_fixture('morty_notifications.json'))
    user = users(:morty)
    user.notifications.destroy_all
    user.download_service.download
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
    user.download_service.download
    notification.reload
    assert notification.unread?
    refute notification.archived?
    attrs = notification.attributes
    assert_equal attrs, attrs.merge(expected_attributes)
  end

  test "#download will set the url for a Repository invitation correctly" do
    stub_notifications_request(body: file_fixture('repository_invitation_notification.json'))
    user = users(:andrew)

    user.download_service.download

    assert notification = Notification.last
    assert_equal 'RepositoryInvitation', notification.subject_type
    assert_match %r{https://github.com/.+/invitations$}, notification.subject_url
  end

  test '#download handles no new notifications' do
    Octokit::Client.any_instance.stubs(:notifications).returns('')
    user = users(:morty)
    user.download_service.download
  end
end
