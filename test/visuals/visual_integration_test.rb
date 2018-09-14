require 'test_helper'
require 'visual_test_helper'

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
    Capybara.current_session.current_window.maximize
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  test 'render a blank index page' do
    visit root_path
    page.has_content?('Sign in')
    Percy::Capybara.snapshot(page, name: '/') if Octobox.config.percy_configured?
  end

  test 'render a logged in user' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path
    
    page.has_selector?('table tr')
    Percy::Capybara.snapshot(page, name: '/:auth') if Octobox.config.percy_configured?

    Capybara.current_session.current_window.resize_to(576,800)
    click_button('sidebar_toggle', wait: 0.25)
    find('.flex-sidebar').visible?
    Percy::Capybara.snapshot(page, name: '/:auth sidebar_toggle') if Octobox.config.percy_configured?
    
    check('select_all')
    find('#select_all').visible?
  end

  test 'render some filtered stuff' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path

    visit '/?starred=true&q=repo%3Aa%2Fb'
    page.has_content?('Nothing to see here.')
    Percy::Capybara.snapshot(page, name: '/?starred=true&q=repo%3Aa%2Fb') if Octobox.config.percy_configured?
  end

  test 'render a docs page' do
    visit documentation_path

    page.has_content?('Documentation')
    Percy::Capybara.snapshot(page, name: '/documentation') if Octobox.config.percy_configured?
    
    Capybara.current_session.current_window.resize_to(576,800)
    click_button('sidebar_toggle', wait: 0.25)
    find('.flex-sidebar').visible?
    Percy::Capybara.snapshot(page, name: '/documentation sidebar_toggle') if Octobox.config.percy_configured?
  end

end
