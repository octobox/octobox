require 'test_helper'

class ProtectFromForgeryTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
  end

  test "raises an exception if request is made without key" do
    assert_raises ActionController::InvalidAuthenticityToken do
      post "/notifications/sync.json"
    end
  end

  test "doesn't raise an exception if request is made with custom API header" do
    post "/notifications/sync.json", headers: { ApplicationController::API_HEADER => 'true' }
    assert_response :unauthorized
  end
end
