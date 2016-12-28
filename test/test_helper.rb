# frozen_string_literal: true

require "simplecov"
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

FactoryGirl.find_definitions

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include FactoryGirl::Syntax::Methods
  include ApiStubHelper
end

class ActionDispatch::IntegrationTest
  include SignInHelper
  include ApiStubHelper
end
