# frozen_string_literal: true
require Rails.root.join('lib/octobox')

Octokit.configure do |c|
  c.api_endpoint = Octobox.config.github_api_prefix
  c.web_endpoint = Octobox.config.github_domain
end
