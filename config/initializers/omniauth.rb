# frozen_string_literal: true
Rails.application.config.middleware.use OmniAuth::Builder do
  site          = 'https://api.github.com'
  authorize_url = 'https://github.com/login/oauth/authorize'
  token_url     = 'https://github.com/login/oauth/access_token'

  if (github_domain = ENV.fetch('GITHUB_DOMAIN', nil))
    site          = "#{github_domain}/api/v3"
    authorize_url = "#{github_domain}/login/oauth/authorize"
    token_url     = "#{github_domain}/login/oauth/access_token"
  end

  provider :github,
           Rails.application.secrets.github_client_id,
           Rails.application.secrets.github_client_secret,
           client_options: { site: site, authorize_url: authorize_url, token_url: token_url },
           scope: ENV.fetch('GITHUB_SCOPE', 'notifications')
end
