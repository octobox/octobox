require 'test_helper'

class NotificationsHelperTest < ActionView::TestCase
  test 'returns true when equal' do
    query = "inbox:true state:open unread:true reason:team_mention"
    assert search_query_matches?(query, query), "search query should have matched"
  end

  test 'returns false when not equal' do
    query = "inbox:true state:open unread:true reason:team_mention"
    other_query = "inbox:true state:open unread:unread reason:team_mention"
    refute search_query_matches?(query, other_query), "search query should not have matched"
  end

  test 'returns true when equal despite formatting differences' do
    query = "inbox:true state:open unread:true reason:team_mention"
    other_query = "inbox: true state: open unread: true reason: team_mention"
    assert search_query_matches?(query, other_query), "search query should have matched"
  end

  test 'returns true when equal despite formatting differences and order' do
    query = "unread:true reason:team_mention inbox:true state:open"
    other_query = "inbox: true state: open unread: true reason: team_mention"
    assert search_query_matches?(query, other_query), "search query should have matched"
  end
end
