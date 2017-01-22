module StubHelper
  def stub_env(variable, value:)
    ENV.stubs(:[])
    ENV.stubs(:[]).with(variable).returns(value.to_s)
  end

  def stub_organization_membership_request(organization_id:, login:, successful:)
    membership_url = %r{https://api.github.com/organizations/#{organization_id}/members/#{login}}

    headers          = { 'Content-Type' => 'application/json', 'Cache-Control' => 'no-cach, no-store' }
    default_response = { body: nil, headers: headers }

    response = successful ? default_response.merge(status: 204) : default_response.merge(status: 404)

    stub_request(:get, membership_url).to_return(response)
  end

  def stub_team_membership_request(team_id:, login:, successful:)
    membership_url = %r{https://api.github.com/teams/#{team_id}/members/#{login}}

    headers          = { 'Content-Type' => 'application/json', 'Cache-Control' => 'no-cach, no-store' }
    default_response = { body: nil, headers: headers }

    response = successful ? default_response.merge(status: 204) : default_response.merge(status: 404)

    stub_request(:get, membership_url).to_return(response)
  end

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

  def stub_restricted_access_enabled(value: true)
    Octobox.stubs(:restricted_access_enabled).returns(value)
  end

  def stub_contributors(body: nil)
    url = %r{https://api.github.com/repos/.+/.+/contributors.*}
    body ||= file_fixture('contributors.json')
    headers = { 'Content-Type' => 'application/json' }
    stub_request(:get, url).to_return( status: 200, body: body, headers: headers)
  end
end
