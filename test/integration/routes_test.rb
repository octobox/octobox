# frozen_string_literal: true

require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  setup do
    stub_notifications_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @user = create(:user)
  end

  test "responds with a 404 for non admins trying to reach /admin/sidekiq" do
    refute_predicate @user, :admin?

    sign_in_as(@user)

    assert_raises ActionController::RoutingError do
      get "/admin/sidekiq"
      assert_response :not_found
    end
  end

  test "responds with a 200 for admins trying to reach /admin/sidekiq" do
    User.any_instance.stubs(:admin?).returns(true)

    sign_in_as(@user)

    get "/admin/sidekiq"
    assert_response :ok
  end
end
