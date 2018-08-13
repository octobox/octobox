class Subject < ApplicationRecord
  has_many :notifications, foreign_key: :subject_url, primary_key: :url
  has_many :labels, dependent: :delete_all
  has_many :comments, dependent: :delete_all
  has_many :users, through: :notifications

  BOT_AUTHOR_REGEX = /\A(.*)\[bot\]\z/.freeze
  private_constant :BOT_AUTHOR_REGEX

  def author_url
    "#{Octobox.config.github_domain}#{author_url_path}"
  end

  def update_labels(remote_labels)
    remote_labels.each do |l|
      label = labels.find_by_github_id(l.id)
      if label.nil?
        labels.create({
          github_id: l.id,
          color: l.color,
          name: l.name,
        })
      else
        label.github_id = l.id # smoothly migrate legacy labels
        label.color = l.color
        label.name = l.name
        label.save if label.changed?
      end
    end
  end

  def sync_involved_users
    user_ids.each { |user_id| SyncNotificationsWorker.perform_async(user_id) }
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
