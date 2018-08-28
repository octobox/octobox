module Octobox
  class Configurator
    def attr_encyrption_key
      @key ||= begin
        key = ENV['OCTOBOX_ATTRIBUTE_ENCRYPTION_KEY']

        if key.nil?
          Rails.application.secret_key_base[0..31]
        elsif key.size != 32
          raise ArgumentError,
            'Must provide a 32 byte encryption key as the env var OCTOBOX_ATTRIBUTE_ENCRYPTION_KEY'
        else
          key
        end
      end
    end

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
      default_scopes = 'notifications'
      default_scopes += ', read:org' if !github_app && Octobox.restricted_access_enabled?
      default_scopes += ', repo'     if !github_app && fetch_subject

      ENV.fetch('GITHUB_SCOPE', default_scopes)
    end

    def github_app
      @github_app || ENV['GITHUB_APP_ID'].present?
    end
    attr_writer :github_app

    def fetch_subject
      @fetch_subject || (ENV['FETCH_SUBJECT'].try(:downcase) == "true")
    end
    attr_writer :fetch_subject

    def subjects_enabled?
      github_app || fetch_subject
    end

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
    attr_writer :max_concurrency

    def sidekiq_schedule_enabled?
      @sidekiq_schedule_enabled || ENV['OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED'].present?
    end
    attr_writer :sidekiq_schedule_enabled

    def sidekiq_schedule_path
      @sidekiq_schedule_path || ENV.fetch('OCTOBOX_SIDEKIQ_SCHEDULE_PATH', Rails.root.join('config', 'sidekiq_schedule.yml'))
    end
    attr_writer :sidekiq_schedule_path

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

    def app_install_url
      "#{app_url}/installations/new"
    end
    attr_writer :app_install_url

    def app_url
      "#{github_domain}/apps/#{app_slug}"
    end
    attr_writer :app_url

    def app_slug
      ENV['GITHUB_APP_SLUG']
    end
    attr_writer :app_slug

    def octobox_io
      @octobox_io || ENV['OCTOBOX_IO'].present?
    end
    attr_writer :octobox_io

    def redis_url
      return @redis_url if defined?(@redis_url)
      @redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    end

    def github_admin_ids
      return @github_admin_ids if defined?(@github_admin_ids)
      admin_github_ids = ENV.fetch("ADMIN_GITHUB_IDS", "").to_s

      return @admin_github_ids = [] unless admin_github_ids.present?
      @github_admin_ids = admin_github_ids.split(',')
    end
  end
end
