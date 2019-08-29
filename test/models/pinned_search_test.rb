# frozen_string_literal: true
require 'test_helper'

class PinnedSearchTest < ActiveSupport::TestCase
  setup do
    @pinned_search = create(:pinned_search)
  end

  test 'must have a name' do
    @pinned_search.name = nil
    refute @pinned_search.valid?
  end

  test 'must have a query' do
    @pinned_search.query = nil
    refute @pinned_search.valid?
  end

  test 'must have a user_id' do
    @pinned_search.user_id = nil
    refute @pinned_search.valid?
  end

  test 'formats query on save' do
    @pinned_search.query = "inbox: true state: open unread: true reason: team_mention"
    @pinned_search.save
    assert_equal "inbox:true state:open unread:true reason:team_mention", @pinned_search.query
  end
end
