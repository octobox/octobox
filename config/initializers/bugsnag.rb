if Rails.application.credentials.bugsnag_api_key.present?
  Bugsnag.configure do |config|
    config.api_key = Rails.application.credentials.bugsnag_api_key
    config.release_stage = ENV["RAILS_ENV"]
    config.app_version = ENV['HEROKU_RELEASE_VERSION']
  end
end
