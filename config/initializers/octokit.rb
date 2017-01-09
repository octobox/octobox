# frozen_string_literal: true
Octokit.configure do |c|
  c.api_endpoint = Octobox.github_api_prefix
  c.web_endpoint = Octobox.github_domain
end
