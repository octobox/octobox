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

    def contributors
      @contributors ||= Octokit::Client.new(auto_paginate: true).contributors(Octokit::Repository.from_url(config.source_repo))
    rescue
      []
    end
  end
end
