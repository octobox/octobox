require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

Sidekiq::Testing.fake!
Sidekiq.logger = nil
Octobox.config.background_jobs_enabled = true

def inline_sidekiq_status
  Sidekiq::Status.stubs(:status).returns(:complete)
  yield
ensure
  Sidekiq::Status.unstub(:status)
end

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end

  def with_background_jobs_enabled(enabled: true)
    original = Octobox.background_jobs_enabled?
    Octobox.config.background_jobs_enabled = enabled
    yield
  ensure
    Octobox.config.background_jobs_enabled = original
  end
end
