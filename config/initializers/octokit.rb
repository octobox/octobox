# frozen_string_literal: true
if (github_domain = ENV.fetch('GITHUB_DOMAIN', nil))
  Octokit.configure do |c|
    c.api_endpoint = "#{github_domain}/api/v3"
    c.web_endpoint = github_domain
  end
end
