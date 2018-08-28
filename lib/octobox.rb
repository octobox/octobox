require 'octobox/configurator'

module Octobox
  class << self
    def config
      @config ||= Configurator.new
      if block_given?
        yield @config
      end
      @config
    end

    def refresh_interval_enabled?
      config.minimum_refresh_interval > 0
    end

    def personal_access_tokens_enabled?
      config.personal_access_tokens_enabled
    end

    def restricted_access_enabled?
      config.restricted_access_enabled
    end

    def github_app?
      config.github_app
    end
  end
end
