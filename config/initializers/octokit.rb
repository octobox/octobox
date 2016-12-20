# frozen_string_literal: true
if (domain = ENV.fetch('DOMAIN', nil))
  Octokit.configure do |c|
    c.api_endpoint = "https://github.#{domain}/api/v3"
    c.web_endpoint = "https://github.#{domain}"
  end
end
