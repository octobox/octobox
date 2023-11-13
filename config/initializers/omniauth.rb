# frozen_string_literal: true
module OmniAuth
  module Strategies
    class GithubApp < GitHub
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  site          = Octobox.config.github_api_prefix
  authorize_url = "#{Octobox.config.github_domain}/login/oauth/authorize"
  token_url     = "#{Octobox.config.github_domain}/login/oauth/access_token"

  provider :github,
           Octobox.config.github_client_id,
           Octobox.config.github_client_secret,
           client_options: { site: site, authorize_url: authorize_url, token_url: token_url },
           scope: Octobox.config.scopes

  if Octobox.github_app?
    provider :github_app,
            Octobox.config.github_app_client_id,
            Octobox.config.github_app_client_secret,
            client_options: { site: site, authorize_url: authorize_url, token_url: token_url }
  end
end
