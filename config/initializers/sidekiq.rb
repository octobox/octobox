# frozen_string_literal: true

if Octobox.config.sidekiq_schedule_enabled? && !Octobox.config.background_jobs_enabled?
  raise ArgumentError, <<~EOF
  You have enabled sidekiq schedule, but have not enabled background jobs.
  Please set the `OCTOBOX_BACKGROUND_JOBS_ENABLED` env var, or unset `OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED`
  EOF
end

if Octobox.config.background_jobs_enabled?
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
end
