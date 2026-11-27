# frozen_string_literal: true
require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_comments_requests
    @user = create(:user)
  end

  test 'renders the not found page with a 404' do
    sign_in_as(@user)
    get '/404'
    assert_response :not_found
    assert_template 'errors/not_found'
  end

  test 'renders the unprocessable page with a 422' do
    sign_in_as(@user)
    get '/422'
    assert_response :unprocessable_content
    assert_template 'errors/unprocessable'
  end

  test 'renders the internal error page with a 500' do
    sign_in_as(@user)
    get '/500'
    assert_response :internal_server_error
    assert_template 'errors/internal'
  end

  test 'renders the error pages when signed out' do
    { '/404' => :not_found, '/422' => :unprocessable_content, '/500' => :internal_server_error }.each do |path, status|
      get path
      assert_response status
    end
  end
end
