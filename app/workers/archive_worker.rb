class ArchiveWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user, lock: :until_and_while_executing

  def perform(user_id, notification_ids, undo_action_id = nil)
    user = User.find_by_id(user_id)
    return unless user

    undo_action = NotificationUndoAction.find_by(id: undo_action_id) if undo_action_id
    return if undo_action_id && !undo_action&.expired?

    Notification.archive_on_github(user, notification_ids)
    undo_action&.destroy
  end
end
