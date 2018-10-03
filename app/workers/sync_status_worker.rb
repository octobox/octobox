# frozen_string_literal: true

class SyncStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(sha, state)
    Subject.sync_status(sha, state)
  end
end
