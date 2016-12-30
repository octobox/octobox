module Octobox
  class <<self
    def personal_access_tokens_enabled
      @personal_access_tokens_enabled || ENV['PERSONAL_ACCESS_TOKENS_ENABLED'].present?
    end
    attr_writer :personal_access_tokens_enabled

    def personal_access_tokens_enabled?
      personal_access_tokens_enabled
    end
  end
end
