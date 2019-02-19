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
end
