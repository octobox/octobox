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

  test 'results applies negation to boolean prefixes' do
    bot_subject = create(:subject, author: 'dependabot[bot]')
    human_subject = create(:subject, author: 'octocat')
    labelled_subject = create(:subject, author: 'octocat')
    create(:label, subject: labelled_subject)

    bot_notification = create(:notification, subject_url: bot_subject.url, starred: true)
    human_notification = create(:notification, subject_url: human_subject.url, starred: false)
    labelled_notification = create(:notification, subject_url: labelled_subject.url)
    scope = Notification.where(id: [bot_notification.id, human_notification.id, labelled_notification.id])

    assert_equal [human_notification.id, labelled_notification.id].sort,
      Search.new(query: '-bot:true', scope: scope).results.pluck(:id).sort
    assert_equal [bot_notification.id],
      Search.new(query: 'bot:true -bot:false', scope: scope).results.pluck(:id).sort
    assert_equal [human_notification.id, labelled_notification.id].sort,
      Search.new(query: '-starred:true', scope: scope).results.pluck(:id).sort
    assert_equal [bot_notification.id, human_notification.id, labelled_notification.id].sort,
      Search.new(query: '-unlabelled:false', scope: scope).results.pluck(:id).sort
  end

  test 'reports unsupported negated prefixes' do
    search = Search.new(query: '-sort:updated -freetext:foo -unlabelled:true -bot:true', scope: Notification.none)

    assert_equal ['-sort', '-freetext', '-unlabelled'], search.unsupported_negated_prefixes
    assert_equal 'Negation is not supported for -sort, -freetext, -unlabelled.', search.unsupported_negation_message
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

  test 'converts number params to number prefix without changing it' do
    search = Search.new(query: 'inbox:true', scope: Notification.all, params: {number: '123'})
    assert_equal search.to_query, 'inbox:true number:123'
  end

  test 'converts archive query without adding index:true' do
    search = Search.new(query: 'type:release archived:true', scope: Notification.all, params: {})
    assert_equal search.to_query, 'type:release archived:true'
  end

  test 'inbox hides snoozed notifications by default' do
    user = create(:user)
    inbox = create(:notification, user: user, archived: false)
    create(:notification, user: user, archived: false, snooze_until: 1.hour.from_now)
    search = Search.new(query: '', scope: user.notifications, params: {})
    assert_equal search.results.pluck(:id), [inbox.id]
  end

  test 'snoozed:true returns only snoozed notifications' do
    user = create(:user)
    create(:notification, user: user, archived: false)
    snoozed = create(:notification, user: user, archived: false, snooze_until: 1.hour.from_now)
    search = Search.new(query: 'snoozed:true', scope: user.notifications, params: {})
    assert_equal search.results.pluck(:id), [snoozed.id]
  end

  test 'converts snoozed param to snoozed prefix' do
    search = Search.new(query: '', scope: Notification.all, params: {snoozed: 'true'})
    assert_equal search.to_query, 'snoozed:true'
    assert search.snoozed_selected?
  end

  test 'Allow rejecting multiple statuses' do
    search = Search.new(query: '-status:merged -status:closed', scope: Notification.all, params: {})
    assert_equal search.results.length, 0
  end
end
