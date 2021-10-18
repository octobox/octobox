# frozen_string_literal: true

class SyncSubjectWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, lock: :until_and_while_executing

  def perform(remote_subject)
    Subject.sync(remote_subject)
  end
end
