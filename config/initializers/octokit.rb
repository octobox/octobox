# frozen_string_literal: true
Octokit.configure do |c|
  c.api_endpoint = Octobox.config.github_api_prefix
  c.web_endpoint = Octobox.config.github_domain
end
