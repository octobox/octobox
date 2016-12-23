if Rails.env.production? && ENV['BUGSNAG_API_KEY'].present?
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY']
  end
end
