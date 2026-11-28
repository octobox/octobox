require 'test_helper'

class NotificationUndoActionTest < ActiveSupport::TestCase
  test 'record_archive stores previous archived states' do
    user = create(:user)
    notification1 = create(:notification, user: user, archived: false)
    notification2 = create(:notification, user: user, archived: true)

    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: [notification1.id, notification2.id]))

    states = undo_action.notification_states.index_by { |state| state['id'] }
    assert_equal false, states[notification1.id]['archived']
    assert_equal true, states[notification2.id]['archived']
    assert undo_action.expires_at.future?
  end

  test 'record_archive stores the action type' do
    user = create(:user)
    create(:notification, user: user)

    assert_equal 'archive', NotificationUndoAction.record_archive!(user, user.notifications).action
    assert_equal 'unarchive', NotificationUndoAction.record_archive!(user, user.notifications, archived: false).action
  end

  test 'record_archive only deletes expired undo actions for the same user' do
    user = create(:user)
    other_user = create(:user)
    notification = create(:notification, user: user)
    create(:notification, user: other_user)
    expired_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id), archived: false)
    other_expired_action = NotificationUndoAction.record_archive!(other_user, other_user.notifications, archived: false)
    expired_action.update!(expires_at: 1.minute.ago)
    other_expired_action.update!(expires_at: 1.minute.ago)

    NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))

    refute NotificationUndoAction.exists?(expired_action.id)
    assert NotificationUndoAction.exists?(other_expired_action.id)
  end

  test 'record_archive keeps expired archive actions until their GitHub archive runs' do
    user = create(:user)
    notification = create(:notification, user: user)
    expired_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))
    expired_action.update!(expires_at: 1.minute.ago)

    NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))

    assert NotificationUndoAction.exists?(expired_action.id)
  end

  test 'restore reverts archived states and destroys the undo action' do
    user = create(:user)
    notification1 = create(:notification, user: user, archived: false)
    notification2 = create(:notification, user: user, archived: true)
    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: [notification1.id, notification2.id]))

    notification1.update!(archived: true)
    notification2.update!(archived: false)

    assert undo_action.restore!
    refute notification1.reload.archived?
    assert notification2.reload.archived?
    refute NotificationUndoAction.exists?(undo_action.id)
  end

  test 'restore does not revert expired undo action' do
    user = create(:user)
    notification = create(:notification, user: user, archived: false)
    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))
    undo_action.update!(expires_at: 1.minute.ago)
    notification.update!(archived: true)

    refute undo_action.restore!
    assert notification.reload.archived?
    assert NotificationUndoAction.exists?(undo_action.id)
  end

  test 'record_snooze stores previous snooze_until states' do
    user = create(:user)
    prev = 2.hours.from_now
    notification1 = create(:notification, user: user, snooze_until: nil)
    notification2 = create(:notification, user: user, snooze_until: prev)

    undo_action = NotificationUndoAction.record_snooze!(user, user.notifications.where(id: [notification1.id, notification2.id]))

    assert_equal 'snooze', undo_action.action
    states = undo_action.notification_states.index_by { |state| state['id'] }
    assert_nil states[notification1.id]['snooze_until']
    assert_equal NotificationUndoAction.serialize_timestamp(prev), states[notification2.id]['snooze_until']
  end

  test 'restore reverts snooze_until for a snooze action' do
    user = create(:user)
    notification1 = create(:notification, user: user, snooze_until: nil)
    notification2 = create(:notification, user: user, snooze_until: 2.hours.from_now)
    undo_action = NotificationUndoAction.record_snooze!(user, user.notifications.where(id: [notification1.id, notification2.id]))

    Notification.snooze([notification1, notification2], 1.day.from_now)

    assert undo_action.restore!
    assert_nil notification1.reload.snooze_until
    assert notification2.reload.snooze_until.present?
    refute NotificationUndoAction.exists?(undo_action.id)
  end
end
