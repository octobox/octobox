require 'test_helper'

class ErrorPagesTest < ActionDispatch::IntegrationTest
  def check_for_redirect
    assert_match 'You are being', response.body
    assert_select "a[href=?]", 'http://www.example.com/', text: 'redirected'
    follow_redirect!
    assert_template root_path
  end

  test '404 not found page' do
    get '/404'
    check_for_redirect
  end

  test '422 unprocessable page' do
    get '/422'
    check_for_redirect
  end

  test '500 internal error page' do
    get '/500'
    check_for_redirect
  end
end
