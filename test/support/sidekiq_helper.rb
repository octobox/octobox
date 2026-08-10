require 'sidekiq_unique_jobs/testing'

Sidekiq.testing!(:fake)
Octobox.config.background_jobs_enabled = true

def inline_sidekiq_status
  Sidekiq::Status.stubs(:status).returns(:complete)
  yield
ensure
  Sidekiq::Status.unstub(:status)
end

NULL_LOGGER = Logger.new(IO::NULL)
cfg = Sidekiq::Config.new
cfg.logger = NULL_LOGGER
cfg.logger.level = Logger::WARN
Sidekiq.instance_variable_set :@config, cfg

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end

  def assert_sidekiq_job_enqueued(worker, *args)
    assert_equal 1, worker.jobs.count { |job| job['args'] == args }
  end

  def with_background_jobs_enabled(enabled: true)
    original = Octobox.background_jobs_enabled?
    Octobox.config.background_jobs_enabled = enabled
    yield
  ensure
    Octobox.config.background_jobs_enabled = original
  end
end
