# frozen_string_literal: true

require "simplecov"
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/minitest'
require 'capybara/rails'
require 'capybara/minitest'

# allow webmock to connect to percy for local testing
WebMock.allow_net_connect!
Percy::Capybara.initialize_build
MiniTest.after_run { Percy::Capybara.finalize_build }

Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

FactoryBot.find_definitions

puts "We are using #{ActiveRecord::Base.connection.adapter_name}"

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

  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Reset sessions and driver between tests
  # Use super wherever this method is redefined in your individual test classes
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
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
    JSON.parse(file_fixture(fixture_file).read, object_class: OpenStruct).tap do |notifications|
      notifications.map { |n| n.last_read_at = Time.parse(n.last_read_at).to_s if n.last_read_at }
    end
  end
end
