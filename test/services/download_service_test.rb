# frozen_string_literal: true
require 'test_helper'

class DownloadServiceTest < ActiveSupport::TestCase
  include NotificationTestHelper

  test '#download fetches all read notification for a new user' do
    stub_fetch_subject_enabled(value: false)
    user = create(:user, last_synced_at: nil)
    all_notifications = notifications_from_fixture('newuser_all_notifications.json')
    expected_attributes = build_expected_attributes(all_notifications)
    download_service = DownloadService.new(user)
    stub_notifications_request(
      url: 'https://api.github.com/notifications?all=true&per_page=100',
      body: file_fixture('newuser_all_notifications.json')
    )
    stub_notifications_request(
      url: 'https://api.github.com/notifications?per_page=100',
      body: file_fixture('newuser_notifications.json')
    )
    download_service.download
    notifications = user.notifications.map(&:attributes)
    expected_attributes.each do |expected|
      assert attrs = notifications.select{|n| n['github_id'] == expected['github_id']}.first
      assert_equal attrs, attrs.merge(expected)
    end
  end

  test '#download fetches notifications newer than the oldest unread' do
    stub_fetch_subject_enabled(value: false)
    user = create(:morty)
    create(:notification, last_read_at: 5.days.ago, updated_at: 30.minutes.ago, user: user)
    download_service = DownloadService.new(user)
    stub_notifications_request(
      url: "https://api.github.com/notifications?all=true&per_page=100"
    )
    stub_notifications_request(
      url: 'https://api.github.com/notifications?per_page=100'
    )
    download_service.download
  end

  test '#download will create new notification' do
    stub_fetch_subject_enabled(value: false)
    expected_attributes = build_expected_attributes(notifications_from_fixture('morty_notifications.json'))
    stub_notifications_request(body: file_fixture('morty_notifications.json'))
    user = create(:morty)
    user.notifications.destroy_all
    user.download_service.download
    notifications = user.notifications.map(&:attributes)
    expected_attributes.each do |expected|
      assert attrs = notifications.select{|n| n['github_id'] == expected['github_id']}.first
      assert_equal attrs, attrs.merge(expected)
    end
  end

  test "#download will update and unarchive a notification" do
    stub_fetch_subject_enabled(value: false)
    expected_attributes =  build_expected_attributes(notifications_from_fixture('morty_notifications.json'))
                             .find{|n| n['github_id'] == 2147650093}
    stub_notifications_request(body: file_fixture('morty_notifications.json'))
    user = create(:morty)
    notification = user.notifications.find_by_github_id(2147650093)
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
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request(body: file_fixture('repository_invitation_notification.json'))
    user = create(:user)

    user.download_service.download

    assert notification = Notification.last
    assert_equal 'RepositoryInvitation', notification.subject_type
    assert_match %r{https://github.com/.+/invitations$}, notification.subject_url
  end

  test '#download handles no new notifications' do
    user = create(:morty)
    download_service = DownloadService.new(user)
    stub_notifications_request(
      url: "https://api.github.com/notifications?all=true&per_page=100",
      body: ''
    )
    stub_notifications_request(
      url: 'https://api.github.com/notifications?per_page=100',
      body: ''
    )
    download_service.download
  end
end
