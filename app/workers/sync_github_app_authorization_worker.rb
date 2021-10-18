# frozen_string_literal: true

class SyncGithubAppAuthorizationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :marketplace, lock: :until_and_while_executing

  def perform(github_id)
    user = User.find_by_github_id(github_id)
    user.update(app_token: nil) if user.present?
  end
end
