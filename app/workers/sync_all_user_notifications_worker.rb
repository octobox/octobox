# frozen_string_literal: true

class SyncAllUserNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_notifications, unique: :until_and_while_executing

  def perform
    User.find_each(&:sync_notifications)
  end
end
