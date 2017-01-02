module Octobox
  class <<self
    def personal_access_tokens_enabled
      @personal_access_tokens_enabled || ENV['PERSONAL_ACCESS_TOKENS_ENABLED'].present?
    end
    attr_writer :personal_access_tokens_enabled

    def personal_access_tokens_enabled?
      personal_access_tokens_enabled
    end

    def minimum_refresh_interval
      @minimum_refresh_interval || ENV['MINIMUM_REFRESH_INTERVAL'].to_i
    end
    attr_writer :minimum_refresh_interval

    def refresh_interval_enabled?
      minimum_refresh_interval > 0
    end
  end
end
