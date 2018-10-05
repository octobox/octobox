# frozen_string_literal: true
require 'test_helper'

class PageLimitingOctokitClientTest < ActiveSupport::TestCase
  include NotificationTestHelper

  test 'notifications page until the end without max_results' do
    setup_paging_stubs
    client = create(:morty).github_client.dup.extend(PageLimitingOctokitClient)
    fetched_notifications = client.notifications(per_page: 2)
    assert_equal 12, fetched_notifications.size
  end

  test 'notification pages stop at max_results' do
    setup_paging_stubs
    client = create(:morty).github_client.dup.extend(PageLimitingOctokitClient)
    fetched_notifications = client.notifications(per_page: 2, max_results:5)
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
      notifications = Oj.load(file_fixture('morty_notifications.json').read)
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
