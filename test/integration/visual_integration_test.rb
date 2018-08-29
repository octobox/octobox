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

  test 'render a blank index page' do
    visit root_path
    Percy::Capybara.snapshot(page, name: '/')
    page.has_content?('Sign in')
  end

  test 'render a logged in user' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path
    Percy::Capybara.snapshot(page, name: '/:auth')
    click_button('sidebar_toggle')
    Percy::Capybara.snapshot(page, name: '/:auth sidebar_toggle')
    check('select_all')
    Percy::Capybara.snapshot(page, name: '/:auth select_all')
    page.has_selector?('table tr')
  end

  test 'render some filtered stuff' do
    sign_in_as(@user)
    stub_fetch_subject_enabled
    visit login_path
    visit '/?starred=true&q=repo%3Aa%2Fb'
    Percy::Capybara.snapshot(page, name: '/?starred=true&q=repo%3Aa%2Fb select_all')
    page.has_selector?('table tr')
  end

  test 'render a the page' do
    visit documentation_path
    Percy::Capybara.snapshot(page, name: '/documentation')
    click_button('sidebar_toggle')
    Percy::Capybara.snapshot(page, name: '/documentation sidebar_toggle')
    page.has_content?('Documentation')
  end

end
