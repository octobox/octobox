# frozen_string_literal: true
require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'will render the documentation page' do
    get '/documentation'
    assert_response :success
    assert_template 'pages/documentation'
  end

  test 'support page renders the documentation page' do
    get '/support'
    assert_response :redirect
    assert_redirected_to '/documentation#support'
  end

  test 'privacy page renders the home page if OCTOBOX_IO is not set' do
    get privacy_path
    assert_response :redirect
    assert_redirected_to '/422'
  end

  test 'will render the privacy page if OCTOBOX_IO is set to true' do
    set_env('OCTOBOX_IO', 'true') do
      get privacy_path
      assert_response :success
      assert_template 'pages/privacy'
    end
  end

  test 'terms page renders the home page if OCTOBOX_IO is not set' do
    get terms_path
    assert_response :redirect
    assert_redirected_to '/422'
  end

  test 'will render the terms page if OCTOBOX_IO is set to true' do
    set_env('OCTOBOX_IO', 'true') do
      get terms_path
      assert_response :success
      assert_template 'pages/terms'
    end
  end
end
