# frozen_string_literal: true

module Octobox
  REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379")
end
