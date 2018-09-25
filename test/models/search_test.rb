require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  test 'user acts as an alias for owner' do
    search = Search.new(query: 'user:andrew', scope: Notification.all)
    assert_equal search.send(:owner), ['andrew']
  end

  test 'org acts as an alias for owner' do
    search = Search.new(query: 'org:octobox', scope: Notification.all)
    assert_equal search.send(:owner), ['octobox']
  end

  test '-user acts as an alias for -owner' do
    search = Search.new(query: '-user:andrew', scope: Notification.all)
    assert_equal search.send(:exclude_owner), ['andrew']
  end

  test '-org acts as an alias for -owner' do
    search = Search.new(query: '-org:octobox', scope: Notification.all)
    assert_equal search.send(:exclude_owner), ['octobox']
  end
end
