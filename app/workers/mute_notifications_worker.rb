class MuteNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user, unique: :until_and_while_executing

  def perform(user_id, notification_ids)
    user = User.find_by_id(user_id)
    Notification.mute_on_github(user, notification_ids) if user
  end
end
