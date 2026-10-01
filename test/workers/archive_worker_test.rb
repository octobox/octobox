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

  test 'reschedules GitHub archive while undo action is still active' do
    user = create(:user)
    notification = create(:notification, user: user)
    undo_action = NotificationUndoAction.record_archive!(user, user.notifications.where(id: notification.id))

    Notification.expects(:archive_on_github).never

    ArchiveWorker.new.perform(user.id, [notification.github_id], undo_action.id)

    assert NotificationUndoAction.exists?(undo_action.id)
    assert_equal 1, ArchiveWorker.jobs.size
    assert_equal [user.id, [notification.github_id], undo_action.id], ArchiveWorker.jobs.first['args']
    assert_in_delta undo_action.expires_at.to_f + NotificationUndoAction::ARCHIVE_BUFFER, ArchiveWorker.jobs.first['at'], 2
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

  test 'archives on GitHub when another archive runs after the undo window but before the worker' do
    user = create(:user)
    notification1 = create(:notification, user: user)
    notification2 = create(:notification, user: user)
    first_notifications = user.notifications.where(id: notification1.id)
    first_action = NotificationUndoAction.record_archive!(user, first_notifications)
    Notification.archive(first_notifications, true, undo_action: first_action)
    first_job = ArchiveWorker.jobs.first

    travel NotificationUndoAction::EXPIRES_IN + 1.second do
      second_notifications = user.notifications.where(id: notification2.id)
      second_action = NotificationUndoAction.record_archive!(user, second_notifications)
      Notification.archive(second_notifications, true, undo_action: second_action)

      assert NotificationUndoAction.exists?(first_action.id)

      Notification.expects(:archive_on_github).with(user, [notification1.github_id]).once

      ArchiveWorker.new.perform(*first_job['args'])
    end

    refute NotificationUndoAction.exists?(first_action.id)
  end
end
