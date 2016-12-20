# frozen_string_literal: true
Rails.application.config.middleware.use OmniAuth::Builder do
  site          = 'https://api.github.com'
  authorize_url = 'https://github.com/login/oauth/authorize'
  token_url     = 'https://github.com/login/oauth/access_token'

  if (domain = ENV.fetch('DOMAIN', nil))
    site          = "https://github.#{domain}/api/v3"
    authorize_url = "https://github.#{domain}/login/oauth/authorize"
    token_url     = "https://github.#{domain}/login/oauth/access_token"
  end

  provider :github,
           Rails.application.secrets.github_client_id,
           Rails.application.secrets.github_client_secret,
           client_options: { site: site, authorize_url: authorize_url, token_url: token_url },
           scope: ENV.fetch('GITHUB_SCOPE', 'notifications')
end
