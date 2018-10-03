# frozen_string_literal: true

class SyncStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(sha, status)
    Subject.sync_status(sha, status)
  end
end
