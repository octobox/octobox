# frozen_string_literal: true

class UpdateInstallationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :marketplace, unique: :until_and_while_executing

  def perform(app_installation_id)
    AppInstallation.find_by_github_id(app_installation_id).try(:sync)
  end
end
