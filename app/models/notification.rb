# frozen_string_literal: true
class Notification < ApplicationRecord
  belongs_to :user

  scope :inbox,    -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :newest,   -> { order('updated_at DESC') }
  scope :starred,  -> { where(starred: true) }

  scope :repo,     ->(repo_name)    { where(repository_full_name: repo_name) }
  scope :type,     ->(subject_type) { where(subject_type: subject_type) }
  scope :reason,   ->(reason)       { where(reason: reason) }
  scope :status,   ->(status)       { where(unread: status) }

  paginates_per 20
  
  def web_url
    subject_url.gsub('https://api.github.com/repos', 'https://github.com')
               .gsub('/pulls/', '/pull/')
               .gsub('/commits/', '/commit/')
  end

  def repo_url
    "https://github.com/#{repository_full_name}"
  end

  def self.download(user)
    user.github_client.notifications(all: true).each do |notification|
      n = Notification.find_or_create_by({github_id: notification.id})
      n.archived = false if n.archived && n.updated_at < notification.updated_at
      n.update_attributes({
        user_id: user.id,
        repository_id: notification.repository.id,
        repository_full_name: notification.repository.full_name,
        subject_title: notification.subject.title,
        subject_url: notification.subject.url,
        subject_type: notification.subject.type,
        reason: notification.reason,
        unread: notification.unread,
        updated_at: notification.updated_at,
        last_read_at: notification.last_read_at,
        url: notification.url})
    end
  end
end
