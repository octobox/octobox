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

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end

    config.server_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Server
    end

    Sidekiq::Status.configure_server_middleware config, expiration: 60.minutes.to_i
    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutess.to_i

    if Rails.env.production?
      config.logger.level = Logger::WARN
    end

    SidekiqUniqueJobs::Server.configure(config)
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: Octobox.config.redis_url }

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end

    Sidekiq::Status.configure_client_middleware config, expiration: 60.minutess.to_i
  end
end
