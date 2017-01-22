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

    def github_domain
      return @github_domain if defined?(@github_domain)
      @github_domain = ENV.fetch('GITHUB_DOMAIN', 'https://github.com')
    end

    def github_api_prefix
      return @github_domain_api_prefix if defined?(@github_domain_api_prefix)

      if (github_domain = ENV.fetch('GITHUB_DOMAIN', nil))
        @github_domain_api_prefix = "#{github_domain}/api/v3"
      else
        @github_domain_api_prefix = "https://api.github.com"
      end
    end
  end
end
