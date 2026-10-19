class ArchiveWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user, lock: :until_and_while_executing

  def perform(user_id, notification_ids, undo_action_id = nil)
    user = User.find_by_id(user_id)
    return unless user

    if undo_action_id
      undo_action = user.notification_undo_actions.find_by(id: undo_action_id)
      return unless undo_action

      unless undo_action.expired?
        self.class.perform_in(undo_action.archive_delay, user_id, notification_ids, undo_action_id)
        return
      end

      notification_ids = undo_action.github_ids_to_archive(notification_ids)
    end

    Notification.archive_on_github(user, notification_ids) if notification_ids.any?
    undo_action&.destroy
  end
end
