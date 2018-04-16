# frozen_string_literal: true

class SyncNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_notifications, unique: :until_executed

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user.present?

    user.sync_notifications

    ActionCable.server.broadcast "sync:#{user.id}", { sync: 'complete' }
  rescue Octokit::Unauthorized, Octokit::Forbidden => exception
    handle_exception(exception, user)
  rescue Octokit::BadGateway, Octokit::ServiceUnavailable => exception
    handle_exception(exception, user)
  rescue Faraday::ClientError => exception
    handle_exception(exception, user)
  end

  private

  def handle_exception(exception, user)
    logger.error("[ERROR] SyncNotificationsJob#perform #{user.github_login} - #{exception.class}: #{exception.message}")
  end
end
