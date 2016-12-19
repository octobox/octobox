# frozen_string_literal: true
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

FactoryGirl.find_definitions

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include FactoryGirl::Syntax::Methods
end



module SignInHelper
  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github].uid = user.github_id
    OmniAuth.config.mock_auth[:github].credentials.token = user.access_token
    post '/auth/github/callback'
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
