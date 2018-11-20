class Comment < ApplicationRecord
  belongs_to :subject

  BOT_AUTHOR_REGEX = /\A(.*)\[bot\]\z/.freeze

  def web_url
    "#{subject.html_url}#issuecomment-#{github_id}"
  end

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

  def unread?(notification)
    notification.last_read_at && DateTime.parse(notification.last_read_at) < created_at
  end
end
