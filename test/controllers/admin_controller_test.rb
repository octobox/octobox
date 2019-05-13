# frozen_string_literal: true
require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_comments_requests
    @user = create(:user)
  end

  test "responds with a 404 for non admins trying to reach /admin" do
    refute_predicate @user, :admin?

    sign_in_as(@user)

    assert_raises ActionController::RoutingError do
      get "/admin"
      assert_response :not_found
    end
  end

  test "responds with a 200 for admins trying to reach /admin" do
    User.any_instance.stubs(:admin?).returns(true)

    sign_in_as(@user)

    get "/admin"
    assert_response :ok
  end
end
