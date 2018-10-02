# frozen_string_literal: true
if Rails.env.production?
  PumaWorkerKiller.config do |config|
    config.ram           = Integer(ENV['DYNO_RAM'] || 512) # mb
    config.frequency     = 5    # seconds
    config.percent_usage = 0.98
    config.rolling_restart_frequency = 6 * 3600 # 6 hours in seconds
    config.reaper_status_logs = false
  end
  PumaWorkerKiller.start
end
