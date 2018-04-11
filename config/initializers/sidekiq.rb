# frozen_string_literal: true

require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: Octobox.config.redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Octobox.config.redis_url }
end

if Octobox.config.sidekiq_schedule_enabled?
  Sidekiq.schedule = YAML.load_file(Octobox.config.sidekiq_schedule_path)
  Sidekiq::Scheduler.reload_schedule!
end
