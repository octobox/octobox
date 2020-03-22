module Octobox
  class Configurator
    def attr_encryption_key
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
      default_scopes += ', read:org' if Octobox.restricted_access_enabled?
      default_scopes += ', repo'     if !github_app && fetch_subject

      ENV.fetch('GITHUB_SCOPE', default_scopes)
    end

    def github_app
      @github_app || ENV['GITHUB_APP_ID'].present?
    end
    attr_writer :github_app

    def fetch_subject
      @fetch_subject || env_boolean('FETCH_SUBJECT')
    end
    attr_writer :fetch_subject

    def subjects_enabled?
      github_app || fetch_subject
    end

    def personal_access_tokens_enabled
      @personal_access_tokens_enabled || env_boolean('PERSONAL_ACCESS_TOKENS_ENABLED')
    end
    attr_writer :personal_access_tokens_enabled

    def minimum_refresh_interval
      @minimum_refresh_interval || env_integer('MINIMUM_REFRESH_INTERVAL')
    end
    attr_writer :minimum_refresh_interval

    def max_notifications_to_sync
      @max_notifications_to_sync || env_integer('MAX_NOTIFICATIONS_TO_SYNC', 500)
    end
    attr_writer :max_notifications_to_sync

    def max_concurrency
      @max_concurrency || env_integer('MAX_CONCURRENCY', 10)
    end
    attr_writer :max_concurrency

    def background_jobs_enabled
      @background_jobs_enabled || sidekiq_schedule_enabled? || env_boolean('OCTOBOX_BACKGROUND_JOBS_ENABLED')
    end
    attr_writer :background_jobs_enabled

    def sidekiq_schedule_enabled?
      @sidekiq_schedule_enabled || env_boolean('OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED')
    end
    attr_writer :sidekiq_schedule_enabled

    def sidekiq_schedule_path
      @sidekiq_schedule_path || ENV.fetch('OCTOBOX_SIDEKIQ_SCHEDULE_PATH', Rails.root.join('config', 'sidekiq_schedule.yml'))
    end
    attr_writer :sidekiq_schedule_path

    def restricted_access_enabled
      @restricted_access_enabled || env_boolean('RESTRICTED_ACCESS_ENABLED')
    end
    attr_writer :restricted_access_enabled

    def github_organization_id
      @github_organization_id || env_integer('GITHUB_ORGANIZATION_ID')
    end
    attr_writer :github_organization_id

    def github_team_id
      @github_team_id || env_integer('GITHUB_TEAM_ID')
    end
    attr_writer :github_team_id

    def native_link
      ENV['OCTOBOX_NATIVE_LINK'] || nil
    end

    def source_repo
      env_value = ENV['SOURCE_REPO'].blank? ? nil : ENV['SOURCE_REPO']
      @source_repo || env_value || 'https://github.com/octobox/octobox'
    end
    attr_writer :source_repo

    def app_install_url
      if marketplace_url.present?
        marketplace_url
      else
        "#{app_url}/installations/new"
      end
    end

    def app_url
      if marketplace_url.present?
        marketplace_url
      else
        static_app_url
      end
    end

    def static_app_url
      "#{github_domain}/#{app_path}/#{app_slug}"
    end

    def app_path
      env_value = ENV['GITHUB_APP_PATH'].blank? ? nil : ENV['GITHUB_APP_PATH']
      @app_path || env_value || 'apps'
    end

    def app_slug
      ENV['GITHUB_APP_SLUG']
    end

    def octobox_io
      @octobox_io || env_boolean('OCTOBOX_IO')
    end
    attr_writer :octobox_io

    def redis_url
      return @redis_url if defined?(@redis_url)
      @redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    end

    def marketplace_url
      ENV['MARKETPLACE_URL']
    end

    def github_admin_ids
      return @github_admin_ids if defined?(@github_admin_ids)
      admin_github_ids = ENV.fetch("ADMIN_GITHUB_IDS", "").to_s

      return @admin_github_ids = [] unless admin_github_ids.present?
      @github_admin_ids = admin_github_ids.split(',')
    end

    def open_in_same_tab
      @open_in_same_tab || env_boolean('OPEN_IN_SAME_TAB')
    end
    attr_writer :open_in_same_tab

    def github_app_jwt
      @github_app_jwt || ENV['GITHUB_APP_JWT']
    end
    attr_writer :github_app_jwt

    def include_comments
      @include_comments || env_boolean('INCLUDE_COMMENTS')
    end
    attr_writer :include_comments

    def push_notifications
      @push_notifications || ENV['PUSH_NOTIFICATIONS']
    end
    attr_writer :push_notifications

    def public_subject_rollout
      @public_subject_rollout || ENV['PUBLIC_SUBJECT_ROLLOUT'].try(:to_time)
    end
    attr_writer :public_subject_rollout

    private

    def env_boolean(env_var_name)
      %w(true 1).include?(ENV[env_var_name].try(:downcase))
    end

    def env_integer(env_var_name, default = nil)
      ENV[env_var_name].try(:to_i) || default
    end
  end
end
