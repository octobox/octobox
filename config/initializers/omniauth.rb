module OmniAuth
  module Strategies
    class GithubApp < GitHub
    end
  end
end


# frozen_string_literal: true
Rails.application.config.middleware.use OmniAuth::Builder do
  site          = Octobox.config.github_api_prefix
  authorize_url = "#{Octobox.config.github_domain}/login/oauth/authorize"
  token_url     = "#{Octobox.config.github_domain}/login/oauth/access_token"

  provider :github,
           Rails.application.secrets.github_client_id,
           Rails.application.secrets.github_client_secret,
           client_options: { site: site, authorize_url: authorize_url, token_url: token_url },
           scope: Octobox.config.scopes

  provider :github_app,
          Rails.application.secrets.github_app_client_id,
          Rails.application.secrets.github_app_client_secret,
          client_options: { site: site, authorize_url: authorize_url, token_url: token_url }
end
