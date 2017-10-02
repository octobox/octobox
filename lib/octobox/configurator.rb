module Octobox
  class Configurator
    def github_domain
      @github_domain || ENV.fetch('GITHUB_DOMAIN', 'https://github.com')
    end
    attr_writer :github_domain

    def github_api_prefix
      return @github_domain_api_prefix if defined?(@github_domain_api_prefix)

      if github_domain != 'https://github.com'
        @github_domain_api_prefix = "#{github_domain}/api/v3"
      else
        @github_domain_api_prefix = "https://api.github.com"
      end
    end

    def scopes
      default_scopes = Octobox.restricted_access_enabled? ? 'notifications, read:org' : 'notifications'
      ENV.fetch('GITHUB_SCOPE', default_scopes)
    end

    def fetch_subject
      @fetch_subject || ENV['FETCH_SUBJECT'].present?
    end
    attr_writer :fetch_subject

    def personal_access_tokens_enabled
      @personal_access_tokens_enabled || ENV['PERSONAL_ACCESS_TOKENS_ENABLED'].present?
    end
    attr_writer :personal_access_tokens_enabled

    def minimum_refresh_interval
      @minimum_refresh_interval || ENV['MINIMUM_REFRESH_INTERVAL'].to_i
    end
    attr_writer :minimum_refresh_interval

    def max_notifications_to_sync
      if @max_notifications_to_sync
        @max_notifications_to_sync
      elsif ENV['MAX_NOTIFICATIONS_TO_SYNC'].present?
        ENV['MAX_NOTIFICATIONS_TO_SYNC'].to_i
      else
        500
      end
    end
    attr_writer :max_notifications_to_sync

    def max_concurrency
      if @max_concurrency
        @max_concurrency
      elsif ENV['MAX_CONCURRENCY'].present?
        ENV['MAX_CONCURRENCY'].to_i
      else
        10
      end
    end
    attr_writer :max_notifications_to_sync

    def restricted_access_enabled
      @restricted_access_enabled || ENV['RESTRICTED_ACCESS_ENABLED'].present?
    end
    attr_writer :restricted_access_enabled

    def github_organization_id
      id = @github_organization_id || ENV['GITHUB_ORGANIZATION_ID']
      return id.to_i if id.present?
    end
    attr_writer :github_organization_id

    def github_team_id
      id = @github_team_id || ENV['GITHUB_TEAM_ID']
      return id.to_i if id.present?
    end
    attr_writer :github_team_id

    def source_repo
      env_value = ENV['SOURCE_REPO'].blank? ? nil : ENV['SOURCE_REPO']
      @source_repo || env_value || 'https://github.com/octobox/octobox'
    end
    attr_writer :source_repo
  end
end
