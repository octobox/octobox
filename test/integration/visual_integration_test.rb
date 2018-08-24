require 'test_helper'

class VisualIntegrationTest < ActionDispatch::IntegrationTest

  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_repository_request
    @user = create(:user)
  end

  # Reset sessions and driver between tests
  # Use super wherever this method is redefined in your individual test classes
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  test 'renders the index page' do
    visit '/'
    Percy::Capybara.snapshot(page, name: '/')
    page.has_content?('Sign in')
  end

  test 'renders the notifications page if authenticated' do
    sign_in_as(@user)
    visit '/'
    Percy::Capybara.snapshot(page, name: '/:auth')
    page.has_selector?('table tr')
  end

end
