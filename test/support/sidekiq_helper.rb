require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end
end
