module StubHelper
  def stub_notifications_request(body: nil)
    notifications_url = %r{https://api.github.com/notifications}

    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)
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

  def stub_personal_access_tokens_enabled(value: 'true')
    Octobox.stubs(:personal_access_tokens_enabled).returns(true)
  end
end
