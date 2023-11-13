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
      config.minimum_refresh_interval && config.minimum_refresh_interval > 0
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

    def io?
      config.octobox_io
    end

    def fetch_subject?
      config.fetch_subject
    end

    def background_jobs_enabled?
      config.background_jobs_enabled
    end

    def include_comments?
      config.include_comments
    end

    def github_app_client
      Octokit::Client.new(bearer_token: generate_jwt, auto_paginate: true)
    end

    def installation_client(app_installation_id)
      Octokit::Client.new(access_token: installation_access_token(app_installation_id), auto_paginate: true)
    end

    def installation_access_token(app_installation_id)
      Octobox.github_app_client.create_installation_access_token(app_installation_id).token
    end

    private

    def generate_jwt
      private_key = OpenSSL::PKey::RSA.new(config.github_app_jwt)

      payload = {
        iat: Time.now.to_i,
        exp: Time.now.to_i + (10 * 60),
        iss: Rails.application.credentials.github_app_id
      }

      JWT.encode(payload, private_key, "RS256")
    end
  end
end
