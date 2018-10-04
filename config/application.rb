require_relative 'boot'
require_relative "../lib/database_config"

require "rails"

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  rails/test_unit/railtie
  sprockets/railtie
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
  end
end
