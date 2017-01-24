# frozen_string_literal: true
Rails.application.config.middleware.use OmniAuth::Builder do
  site          = Octobox.config.github_api_prefix
  authorize_url = "#{Octobox.config.github_domain}/login/oauth/authorize"
  token_url     = "#{Octobox.config.github_domain}/login/oauth/access_token"

  provider :github,
           Rails.application.secrets.github_client_id,
           Rails.application.secrets.github_client_secret,
           client_options: { site: site, authorize_url: authorize_url, token_url: token_url },
           scope: ENV.fetch('GITHUB_SCOPE', 'notifications')
end
