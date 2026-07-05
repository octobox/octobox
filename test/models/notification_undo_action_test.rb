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
end
