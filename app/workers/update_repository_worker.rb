# frozen_string_literal: true

class UpdateRepositoryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(notification_id, force = false)
    Notification.find_by_id(notification_id).try(:update_repository_in_foreground, force)
  end
end
