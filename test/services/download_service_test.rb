# frozen_string_literal: true
require 'test_helper'

class DownloadServiceTest < ActiveSupport::TestCase
  include NotificationTestHelper

  test '#download fetches all read notification for a new user' do
    user = users(:newuser)
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
    user = users(:userwithunread)
    # one second before oldest unread notification
    unread_since =( user.notifications.status(true).first.updated_at - 1).iso8601
    download_service = DownloadService.new(user)
    stub_notifications_request(
      url: "https://api.github.com/notifications?all=true&per_page=100&since=#{unread_since}"
    )
    stub_notifications_request(
      url: 'https://api.github.com/notifications?per_page=100'
    )
    download_service.download
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
    user = users(:morty)
    download_service = DownloadService.new(user)
    unread_since =( user.notifications.status(true).first.updated_at - 1).iso8601
    stub_notifications_request(
      url: "https://api.github.com/notifications?all=true&per_page=100&since=#{unread_since}",
      body: ''
    )
    stub_notifications_request(
      url: 'https://api.github.com/notifications?per_page=100',
      body: ''
    )
    download_service.download
  end

  test 'fetch_notifications pages until the end' do
    setup_paging_stubs
    download_service = DownloadService.new(users(:morty))
    fetched_notifications = download_service.fetch_notifications(params: {per_page: 2}, max_results:50)
    assert_equal 8, fetched_notifications.size
  end

  test 'fetch_notifications pages stops at max_notifications' do
    setup_paging_stubs
    download_service = DownloadService.new(users(:morty))
    fetched_notifications = download_service.fetch_notifications(params: {per_page: 2}, max_results:5)
    assert_equal 5, fetched_notifications.size
  end

  test 'fetch_notifications respects Octobox.config.max_notifications_to_sync' do
    setup_paging_stubs
    Octobox.config.stubs(:max_notifications_to_sync).returns(5)
    download_service = DownloadService.new(users(:morty))
    fetched_notifications = download_service.fetch_notifications(params: {per_page: 2})
    assert_equal 5, fetched_notifications.size
  end

  def setup_paging_stubs
    [
      {
        page_number: 1,
        link_header: '<https://api.github.com/notifications?page=2&per_page=2>; rel="next"'
      },
      {
        page_number: 2,
        link_header: '<https://api.github.com/notifications?page=3&per_page=2>; rel="next"'
      },
      {
        page_number: 3,
        link_header: '<https://api.github.com/notifications?page=4&per_page=2>; rel="next"'
      },
      {
        page_number: 4,
        link_header: '<https://api.github.com/notifications?page=1&per_page=2>; rel="first"'
      }
    ].each do |page|
      notifications = JSON.parse(file_fixture('morty_notifications.json').read)
      id = page[:page_number] * 2
      notifications.each do |n|
        n['id'] = id.to_s
        id += 1
      end
      page_url = page[:page_number] > 1 ?
        "https://api.github.com/notifications?page=#{page[:page_number]}&per_page=2" :
        'https://api.github.com/notifications?per_page=2'
      stub_notifications_request(
        url: page_url,
        body: notifications.to_json,
        extra_headers: {'Link' => page[:link_header]}
      )
    end
  end
end
