require 'test_helper'

class ArchiveWorkerTest < ActiveSupport::TestCase
  test 'archives on GitHub without an undo action' do
    user = create(:user)
    github_ids = [123]

    Notification.expects(:archive_on_github).once

    ArchiveWorker.new.perform(user.id, github_ids)
  end

  test 'skips GitHub archive when undo action was consumed' do
    user = create(:user)
    github_ids = [123]

    Notification.expects(:archive_on_github).never

    ArchiveWorker.new.perform(user.id, github_ids, 12345)
  end

  test 'skips GitHub archive while undo action is still active' do
    user = create(:user)
    notification = create(:notification, user: user)
    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))

    Notification.expects(:archive_on_github).never

    ArchiveWorker.new.perform(user.id, [notification.github_id], undo_action.id)

    assert NotificationUndoAction.exists?(undo_action.id)
  end

  test 'archives on GitHub after undo action expires' do
    user = create(:user)
    notification = create(:notification, user: user)
    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))
    undo_action.update!(expires_at: 1.minute.ago)

    Notification.expects(:archive_on_github).once

    ArchiveWorker.new.perform(user.id, [notification.github_id], undo_action.id)

    refute NotificationUndoAction.exists?(undo_action.id)
  end
end
