Rails.application.config.after_initialize do
  if Octobox.github_app? && Octobox.config.github_webhook_secret.blank? && !Rails.env.test?
    Rails.logger.warn "[octobox] GITHUB_WEBHOOK_SECRET is not set. The /hooks/github endpoint will accept unsigned requests. Set a webhook secret on your GitHub App and in this environment before exposing this instance publicly. See docs/INSTALLATION.md."
  end
end
