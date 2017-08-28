class Subject < ApplicationRecord
  has_many :notifications, foreign_key: :subject_url, primary_key: :url

  def author_url
    "#{Octobox.config.github_domain}/#{author}"
  end
end
