module Octobox
  def self.github_domain
    return @github_domain if defined?(@github_domain)
    @github_domain = ENV.fetch('GITHUB_DOMAIN', 'https://github.com')
  end

  def self.github_api_prefix
    return @github_domain_api_prefix if defined?(@github_domain_api_prefix)

    if (github_domain = ENV.fetch('GITHUB_DOMAIN', nil))
      @github_domain_api_prefix = "#{github_domain}/api/v3"
    else
      @github_domain_api_prefix = "https://api.github.com"
    end
  end
end
