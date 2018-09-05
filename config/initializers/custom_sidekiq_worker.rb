module Sidekiq::Worker
  module ClassMethods
    def perform_async_if_configured(*args)
      if Octobox.background_jobs_enabled?
        perform_async(*args)
      else
        worker = new
        if worker.method(:perform).arity != 0
          worker.perform(*args)
        else
          worker.perform
        end
      end
    end
  end
end
