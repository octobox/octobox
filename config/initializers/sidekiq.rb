# frozen_string_literal: true

if Octobox.background_jobs_enabled?
  require 'sidekiq-scheduler' if Octobox.config.sidekiq_schedule_enabled?
  require 'sidekiq-status'

  Sidekiq.configure_server do |config|
    config.redis = { url: Octobox.config.redis_url }
    if Octobox.config.sidekiq_schedule_enabled?
      config.on(:startup) do
        Sidekiq.schedule = YAML.load_file(Octobox.config.sidekiq_schedule_path)
        Sidekiq::Scheduler.reload_schedule!
      end
    end
    Sidekiq::Status.configure_server_middleware config, expiration: 60.minutes
    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes

    config.death_handlers << ->(job, _ex) do
      SidekiqUniqueJobs::Digests.del(digest: job['unique_digest']) if job['unique_digest']
    end

    if Rails.env.production?
      config.logger.level = Logger::WARN
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: Octobox.config.redis_url }
    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes
  end
end
