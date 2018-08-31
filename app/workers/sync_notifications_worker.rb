# frozen_string_literal: true

class SyncNotificationsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options queue: :sync_notifications, unique: :until_executed

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user.present?

    user.sync_notifications_in_foreground
  rescue Octokit::Unauthorized, Octokit::Forbidden => exception
    handle_exception(exception, user)
  rescue Octokit::BadGateway, Octokit::ServerError, Octokit::ServiceUnavailable => exception
    handle_exception(exception, user)
  rescue Faraday::ClientError => exception
    handle_exception(exception, user)
  end

  private

  def handle_exception(exception, user)
    logger.error("[ERROR] SyncNotificationsJob#perform #{user.github_login} - #{exception.class}: #{exception.message}")
    store(exception: exception.message)
  end
end
