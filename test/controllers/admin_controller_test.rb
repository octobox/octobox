# frozen_string_literal: true
require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    @user = create(:user)
    stub_env_var 'ADMIN_GITHUB_IDS'
  end

  test 'render 404 if user isnt admin' do
    sign_in_as(@user)

    assert_raises ActionController::RoutingError do
      get '/admin'
    end
  end
end
