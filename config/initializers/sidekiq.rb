# frozen_string_literal: true

require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: Octobox.config.redis_url }
  if Octobox.config.sidekiq_schedule_enabled?
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(Octobox.config.sidekiq_schedule_path)
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Octobox.config.redis_url }
end
