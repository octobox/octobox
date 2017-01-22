module Octobox
  class Configurator
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
      @source_repo || ENV['SOURCE_REPO'] || 'https://github.com/octobox/octobox'
    end
    attr_writer :source_repo

    def contributors
      @contributors ||= Octokit::Client.new(auto_paginate: true).contributors(Octokit::Repository.from_url(source_repo))
    rescue
      nil
    end
    attr_writer :contributors
  end
end
