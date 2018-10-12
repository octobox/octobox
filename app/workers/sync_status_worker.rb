# frozen_string_literal: true

class SyncStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(sha, repository_full_name)
    Subject.sync_status(sha, repository_full_name)
  end
end
