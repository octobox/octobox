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

  def stub_notifications_request(url: nil, body: nil, method: :get, extra_headers: {})
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)

    if url.nil?
      stub_request(:get, 'https://api.github.com/repos/octobox/octobox/issues/56')
      .to_return({ status: 200, body: file_fixture('subject_56.json'), headers: headers })
      stub_request(:get, 'https://api.github.com/repos/octobox/octobox/issues/57')
      .to_return({ status: 200, body: file_fixture('subject_57.json'), headers: headers })
      stub_request(:get, 'https://api.github.com/repos/octobox/octobox/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e')
      .to_return({ status: 200, body: file_fixture('commit_no_author.json'), headers: { 'Content-Type' => 'application/json' } })
    end

    url ||= %r{https://api.github.com/notifications}
    body     ||= file_fixture('notifications.json')
    response = { status: 200, body: body, headers: headers }

    stub_request(method, url).to_return(response)
  end

  def stub_comments_requests(extra_headers: {})
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)

    stub_request(:get, /\/comments\?since\z/)
      .to_return({ status: 200, body: file_fixture('comments.json'), headers: headers })
  end

  def stub_access_tokens_request(extra_headers: {})
    Octobox.stubs(:generate_jwt).returns('MIIEpAIBAAKCAQEA8PcoKAOyTG0rl9PUfdgey3smnkF2U0')
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)

    stub_request(:post, /https:\/\/api\.github\.com\/app\/installations\/\d+\/access_tokens\z/)
      .to_return({ status: 200, body: file_fixture('access_token.json'), headers: headers })
  end

  def stub_repository_request(extra_headers: {})
    stub_comments_requests
    headers  = { 'Content-Type' => 'application/json' }.merge(extra_headers)

    stub_request(:get, /https:\/\/api.github.com\/repos\/octobox\/octobox\z/)
      .to_return({ status: 200, body: file_fixture('repository.json'), headers: headers })
  end

  def stub_user_request(body: nil, oauth_scopes: 'notifications', user: nil, any_auth: false)
     # ActiveSupport::TestCase.file_fixture_path
    user_url = %r{https://api.github.com/user}
    unless body
      file_fixture = file_fixture('user.json')
      file_fixture_content = file_fixture.read
      body = Oj.load(file_fixture_content)
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

  def stub_oc_members_request
    transactions_url = "https://opencollective.com/octobox/members.json"

    response = { status: 200, body: file_fixture('oc_members.json'), headers: { 'Content-Type' => 'application/json' } }
    stub_request(:get, transactions_url).to_return(response)
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

  def stub_fetch_subject_enabled(value: true)
    Octobox.config.stubs(:fetch_subject).returns(value)
    Octobox.config.stubs(:github_app).returns(value)
  end

  def stub_background_jobs_enabled(value: true)
    Octobox.config.stubs(:background_jobs_enabled).returns(value)
  end

  def stub_include_comments(value: true)
    Octobox.config.stubs(:include_comments?).returns(value)
  end
end
