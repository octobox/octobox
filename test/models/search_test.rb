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

  test 'converts assigned params to assignee prefix' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {assigned: 'andrew'})
    assert_equal search.to_query, 'inbox:true assignee:andrew'
  end

  test 'converts repo params to repo prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {repo: 'CamelCase/RepoName'})
    assert_equal search.to_query, 'inbox:true repo:CamelCase/RepoName'
  end

  test 'converts owner params to owner prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {owner: 'OwnerName'})
    assert_equal search.to_query, 'inbox:true owner:OwnerName'
  end

  test 'converts author params to author prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {author: 'AuthorName'})
    assert_equal search.to_query, 'inbox:true author:AuthorName'
  end

  test 'converts label params to label prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {label: 'LabelName'})
    assert_equal search.to_query, 'inbox:true label:LabelName'
  end

  test 'converts draft param to draft prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {draft: 'true'})
    assert_equal search.to_query, 'inbox:true draft:true'
  end
end
