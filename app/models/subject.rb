class Subject < ApplicationRecord
  has_many :notifications, foreign_key: :subject_url, primary_key: :url

  BOT_AUTHOR_REGEX = /\A(.*)\[bot\]\z/.freeze
  private_constant :BOT_AUTHOR_REGEX

  def author_url
    "#{Octobox.config.github_domain}#{author_url_path}"
  end

  private

  def author_url_path
    if bot_author?
      "/apps/#{BOT_AUTHOR_REGEX.match(author)[1]}"
    else
      "/#{author}"
    end
  end

  def bot_author?
    BOT_AUTHOR_REGEX.match?(author)
  end
end
