# frozen_string_literal: true
require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'will render the documentation page' do
    get '/documentation'
    assert_response :success
    assert_template 'pages/documentation'
  end
end
