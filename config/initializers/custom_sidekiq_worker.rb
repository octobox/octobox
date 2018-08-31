module Sidekiq::Worker
  module ClassMethods
    def perform_async_if_configured(*args)
      if Octobox.config.background_jobs_enabled?
        perform_async(*args)
      else
        perform(*args)
      end
    end
  end
end
