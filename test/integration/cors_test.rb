require 'test_helper'

class CorsTest < ActionDispatch::IntegrationTest
  test "GET request to API returns CORS headers" do
    get '/api/notifications', headers: { 'Origin' => 'http://example.com' }

    assert_equal '*', response.headers['Access-Control-Allow-Origin']
  end

  test "POST request to API returns CORS headers" do
    post '/api/notifications/sync', headers: { 'Origin' => 'http://example.com' }

    assert_equal '*', response.headers['Access-Control-Allow-Origin']
  end

  test "OPTIONS preflight request returns CORS headers" do
    process :options, '/api/notifications', headers: {
      'Origin' => 'http://example.com',
      'Access-Control-Request-Method' => 'GET'
    }

    assert_equal '*', response.headers['Access-Control-Allow-Origin']
    assert_match(/GET/, response.headers['Access-Control-Allow-Methods'])
  end
end
