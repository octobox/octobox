if ENV['BUGSNAG_API_KEY'].present?
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY']
    config.release_stage = ENV["RAILS_ENV"]
    config.app_version = ENV['HEROKU_RELEASE_VERSION']
  end
end
