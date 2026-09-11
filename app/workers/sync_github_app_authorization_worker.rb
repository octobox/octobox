# frozen_string_literal: true

class SyncGithubAppAuthorizationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :marketplace, lock: :until_and_while_executing

  def perform(github_id)
    User.find_by_github_id(github_id).try(:revoke_app_token!)
  end
end
