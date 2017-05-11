module StubHelper
  def stub_env_var(variable, value = nil)
    stub_env({"#{variable}": value})
  end

  def stub_env(env = {})
    ENV.stubs(:[])
    env.each do |variable, value|
      value = value.to_s unless value.nil?
      ENV.stubs(:[]).with(variable.to_s).returns(value)
    end
  end

  def stub_organization_membership_request(organization_id:, user:, successful:)
    stub_membership_request(resource: 'organizations', id: organization_id, user: user, successful: successful)
  end

  def stub_team_membership_request(team_id:, user:, successful:)
    stub_membership_request(resource: 'teams', id: team_id, user: user, successful: successful)
  end

  def stub_membership_request(resource:, id:, user:, successful:)
    url = %r{https://api.github.com/#{resource}/#{id}/members/#{user}}

    headers = { 'Content-Type' => 'application/json', 'Cache-Control' => 'no-cache, no-store' }
    response = { headers: headers }

    if successful
      response.merge!(
        status: 204,
        body: nil
      )
    else
      response.merge!(
        status: 404,
        body: nil
      )
    end
    stub_request(:get, url).to_return(response)
  end

  def stub_notifications_request(url: nil, body: nil, extra_headers: {})
    url ||= %r{https://api.github.com/notifications}
    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, url).to_return(response)
  end

  def stub_user_request(body: nil, oauth_scopes: 'notifications', user: nil, any_auth: false)
     # ActiveSupport::TestCase.file_fixture_path
    user_url = %r{https://api.github.com/user}
    unless body
      file_fixture = file_fixture('user.json')
      file_fixture_content = file_fixture.read
      body = JSON.parse(file_fixture_content)
      body[:id] = user.github_id if user.respond_to?(:github_id)
      body = body.to_json
    end
    headers  = { 'Content-Type': 'application/json', 'X-OAuth-Scopes': oauth_scopes }
    response = { status: 200, body: body, headers: headers }
    any_auth = true unless user.respond_to?(:effective_access_token)
    if any_auth
      stub_request(:get, user_url).to_return(response)
    else
      request_headers = {Authorization: "token #{user.effective_access_token}"}
      stub_request(:get, user_url).with(headers: request_headers).to_return(response)
    end
  end

  def stub_personal_access_tokens_enabled(value: true)
    Octobox.config.stubs(:personal_access_tokens_enabled).returns(value)
  end

  def stub_minimum_refresh_interval(value = 0)
    Octobox.config.stubs(:minimum_refresh_interval).returns(value)
  end

  def stub_restricted_access_enabled(value: true)
    Octobox.config.stubs(:restricted_access_enabled).returns(value)
  end
end
