# frozen_string_literal: true

class UpdateRepoSubjectsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_repos, lock: :until_and_while_executing

  def perform(repository_id)
    Repository.find_by_id(repository_id)&.sync_subjects_in_foreground
  end
end
