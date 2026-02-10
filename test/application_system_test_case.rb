# frozen_string_literal: true

require 'test_helper'
require 'capybara/minitest'

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: ENV['HEADLESS'] != 'false',
    viewport: { width: 1400, height: 900 }
  )
end

Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
Capybara.default_max_wait_time = 5

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright

  include FactoryBot::Syntax::Methods
  include StubHelper

  setup do
    WebMock.disable_net_connect!(allow_localhost: true)
    stub_user_request(any_auth: true)
    stub_notifications_request
    stub_comments_requests
    stub_repository_request
  end

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github].uid = user.github_id
    OmniAuth.config.mock_auth[:github].info = { 'nickname' => user.github_login }
    OmniAuth.config.mock_auth[:github].credentials.token = user.access_token

    User.any_instance.stubs(:sync_notifications)
    visit '/auth/github/callback'
    assert_text 'Inbox'
  end

  def toggle_notification_checkbox(notification_id)
    checkbox = find("#notification-#{notification_id} .custom-checkbox input", visible: :all)
    checked = checkbox.checked?
    page.execute_script("var cb = document.querySelector('#notification-#{notification_id} .custom-checkbox input'); cb.checked = #{!checked}; $(cb).trigger('change')")
  end

  def toggle_select_all
    page.execute_script("document.querySelector('.js-select_all').click()")
  end
end
