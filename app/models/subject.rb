class Subject < ApplicationRecord
  def author_url
    "#{Octobox.config.github_domain}/#{author}"
  end
end
