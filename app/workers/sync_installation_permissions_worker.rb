# frozen_string_literal: true

class SyncInstallationPermissionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :marketplace, unique: :until_and_while_executing

  def perform(user_id)
    User.find_by_id(user_id).try(:sync_app_installation_access)
  end
end
