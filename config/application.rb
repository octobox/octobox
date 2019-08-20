require_relative 'boot'
require_relative "../lib/database_config"

require "rails"

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  rails/test_unit/railtie
  sprockets/railtie
  action_cable/engine
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Octobox
  class Application < Rails::Application
    config.eager_load_paths << Rails.root.join("lib")
    config.exceptions_app = routes

    config.load_defaults '6.0'

    unless File.basename($0) == 'rake' || File.basename($0) == 'rails' || secrets.secret_key_base.length >= 32
      raise "SECRET_KEY_BASE should be a random key of at least 32 chars."
    end
  end
end
