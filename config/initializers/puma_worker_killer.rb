# frozen_string_literal: true

# return a dyno's ram limit in MB based on: $DYNO_RAM,
# /sys/fs/cgroup/memory/memory.limit_in_bytes, or the default of 512
def dyno_ram
  if !ENV['DYNO_RAM'].nil?
    return Integer(ENV['DYNO_RAM'])
  end
  Integer(Integer(IO.read("/sys/fs/cgroup/memory/memory.limit_in_bytes")) / 1024 / 1024)
  rescue
    return 512
end

if Rails.env.production?
  PumaWorkerKiller.config do |config|
    config.ram           = dyno_ram
    config.frequency     = 5    # seconds
    config.percent_usage = 0.98
    config.rolling_restart_frequency = 6 * 3600 # 6 hours in seconds
    config.reaper_status_logs = false
  end
  PumaWorkerKiller.start
end
