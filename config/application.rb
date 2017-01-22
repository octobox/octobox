require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Octobox
  class Application < Rails::Application
    require Rails.root.join('lib/octobox')
  end
end
