# frozen_string_literal: true

require "rack-mini-profiler"

# Initialization is skipped so trigger it
Rack::MiniProfilerRails.initialize!(Rails.application)

Rack::MiniProfiler.config.position = "bottom-right"

# Set Redis store for production
if Rails.env.production?
  uri = URI.parse(Octobox.config.redis_url)

  Rack::MiniProfiler.config.storage_options = { host: uri.host, port: uri.port, password: uri.password }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
else
  # Set MemoryStore for development
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
end
