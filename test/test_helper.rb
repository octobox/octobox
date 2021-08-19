# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/minitest'

require 'sidekiq_unique_jobs/testing'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

FactoryBot.find_definitions

require 'oj'
Oj.default_options = Oj.default_options.merge(cache_str: -1)

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include FactoryBot::Syntax::Methods
  include SidekiqMinitestSupport
  include StubHelper
end

class ActionDispatch::IntegrationTest
  include SignInHelper
  include StubHelper
end

module NotificationTestHelper
  def build_expected_attributes(expected_notifications, keys: nil)
    keys ||= DownloadService::API_ATTRIBUTE_MAP.keys
    expected_notifications.map{|n|
      notification = Notification.new
      notification.attributes = Notification.attributes_from_api_response(n)
      attrs = notification.attributes
      notification.destroy
      attrs.slice(*(keys.map(&:to_s)))
    }
  end

  def notifications_from_fixture(fixture_file)
    Oj.load(file_fixture(fixture_file).read, object_class: OpenStruct).tap do |notifications|
      notifications.map { |n| n.last_read_at = Time.parse(n.last_read_at).to_s if n.last_read_at }
    end
  end
end

def set_env(key, val)
  original = ENV[key]
  if val
    ENV[key] = val.to_s
  else
    ENV.delete(key)
  end
  yield(val)
ensure
  ENV[key] = original
end
