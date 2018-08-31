require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil
Octobox.config.background_jobs_enabled = true

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end

  def with_background_jobs_enabled(enabled: true)
    original = Octobox.config.background_jobs_enabled?
    Octobox.config.background_jobs_enabled = enabled
    yield
  ensure
    Octobox.config.background_jobs_enabled = original
  end
end
