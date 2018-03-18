# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: Octobox.config.redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Octobox.config.redis_url }
end
