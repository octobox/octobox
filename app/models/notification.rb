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

  class << self
    def download(user)
      timestamp = Time.current

      fetch_notifications(user) do |notification|
        begin
          n = find_or_create_by(github_id: notification.id)

          if n.archived && n.updated_at < notification.updated_at
            n.archived = false
          end

          attrs = {}.tap do |attr|
            attr[:user_id]               = user.id
            attr[:repository_id]         = notification.repository.id
            attr[:repository_full_name]  = notification.repository.full_name
            attr[:repository_owner_name] = notification.repository.owner.login
            attr[:subject_title]         = notification.subject.title
            attr[:subject_type]          = notification.subject.type
            attr[:reason]                = notification.reason
            attr[:unread]                = notification.unread
            attr[:updated_at]            = notification.updated_at
            attr[:last_read_at]          = notification.last_read_at
            attr[:url]                   = notification.url

            attr[:subject_url] = if notification.subject.type == "RepositoryInvitation"
                                   "#{notification.repository.html_url}/invitations"
                                 else
                                   notification.subject.url
                                 end
          end

          n.update(attrs)
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      user.touch(:last_synced_at, time: timestamp)
    end

    private

    def fetch_notifications(user)
      user.github_client.notifications(fetch_params(user)).each { |n| yield n }
    end

    def fetch_params(user)
      if user.last_synced_at?
        { all: true, since: user.last_synced_at.iso8601 }
      else
        { all: true, since: 1.month.ago.iso8601 }
      end
    end
  end

  def web_url
    subject_url.gsub("#{Octobox.github_api_prefix}/repos", Octobox.github_domain)
               .gsub('/pulls/', '/pull/')
               .gsub('/commits/', '/commit/')
  end

  def repo_url
    "#{Octobox.github_domain}/#{repository_full_name}"
  end
end
