# frozen_string_literal: true

class SyncReviewsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, lock: :until_and_while_executing

  def perform(remote_subject)
    Subject.sync_comments(remote_subject)
  end
end
