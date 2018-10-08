# frozen_string_literal: true

class SyncLabelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(payload)
    repository = Repository.find_by_github_id(payload['repository']['id'])
    return if repository.nil?
    return if payload['changes']['name'].nil?

    Label.where(
      name: payload['changes']['name']['from'],
      repository: repository
    ).update_all(
      name: payload['label']['name']
    )
  end
end
