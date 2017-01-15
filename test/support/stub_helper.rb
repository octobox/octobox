module StubHelper
  def stub_notifications_request(url: nil, body: nil, extra_headers: {})
    url ||= %r{https://api.github.com/notifications}
    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, url).to_return(response)
  end

  def stub_user_request(body: nil, oauth_scopes: 'notifications', user: nil)
    user_url = %r{https://api.github.com/user}
    unless body
      body = JSON.parse(file_fixture('user.json').read)
      body[:id] = user.github_id if user.respond_to?(:github_id)
      body = body.to_json
    end
    headers  = { 'Content-Type': 'application/json', 'X-OAuth-Scopes': oauth_scopes }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, user_url).to_return(response)
  end

  def stub_personal_access_tokens_enabled(value: true)
    Octobox.stubs(:personal_access_tokens_enabled).returns(value)
  end

  def stub_minimum_refresh_interval(value = 0)
    Octobox.stubs(:minimum_refresh_interval).returns(value)
  end
end
