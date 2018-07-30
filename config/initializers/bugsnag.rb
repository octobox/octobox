if Rails.application.secrets.bugsnag_api_key.present?
  Bugsnag.configure do |config|
    config.api_key = Rails.application.secrets.bugsnag_api_key
    config.release_stage = ENV["RAILS_ENV"]
  end
end
