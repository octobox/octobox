class Comment < ApplicationRecord
  belongs_to :subject

  after_save :push_to_channels

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

  def push_to_channels
    comment = ApplicationController.render(partial: 'notifications/comment', locals: {subject: self.subject.id, comment: self, comments:1})
    ActionCable.server.broadcast_to self.subject, { comment: comment}
    subjects.find_each(&:push_to_channel) if (saved_changes.keys & pushable_fields).any?
  end

  private

  def pushable_fields
    ['body']
  end
end
