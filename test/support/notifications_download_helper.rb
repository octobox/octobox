module ApiStubHelper
  def stub_notifications_request(body: nil)
    notifications_url = %r{https://api.github.com/notifications}

    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)
  end

  def stub_user_request(body: nil, oauth_scopes: 'notifications')
    user_url = %r{https://api.github.com/user}

    body ||= file_fixture('user.json')
    headers  = { 'Content-Type': 'application/json', 'X-OAuth-Scopes': oauth_scopes }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, user_url).to_return(response)
  end
end
