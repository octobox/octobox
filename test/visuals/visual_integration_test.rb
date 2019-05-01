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

    Capybara.current_session.current_window.resize_to(576,800)
  end

  test 'render a logged in user' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path

    page.has_selector?('table tr')
  end

  test 'render the sidebar on small devices' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path

    Capybara.current_session.current_window.resize_to(576,800)
    click_button('sidebar_toggle', wait: 0.25)
    find('.flex-sidebar').visible?
  end

  test 'render some filtered stuff' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path

    visit '/?starred=true&q=repo%3Aa%2Fb'
    page.has_content?('Nothing to see here.')
  end

  test 'render a docs page' do
    visit documentation_path

    page.has_content?('Documentation')

    Capybara.current_session.current_window.resize_to(576,800)
    click_button('sidebar_toggle', wait: 0.25)
    find('.flex-sidebar').visible?
  end

  test 'Render a dark theme page' do
    sign_in_as(@user)
    set_dark_theme(@user)
    stub_fetch_subject_enabled
    visit login_path

    has_unchecked_field?('label[for=select_all]', visible: :false)
  end
end
