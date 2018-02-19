# frozen_string_literal: true

class SyncNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_notifications, unique: :until_executed

  def perform(user_id)
  end
end
