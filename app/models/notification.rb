# frozen_string_literal: true
class Notification < ApplicationRecord
  include PgSearch
  pg_search_scope :search_by_subject_title,
                  against: :subject_title,
                  using: {
                    tsearch: {
                      prefix: true,
                      negation: true,
                      dictionary: "english"
                    }
                  }

  belongs_to :user

  scope :inbox,    -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :newest,   -> { order('updated_at DESC') }
  scope :starred,  -> { where(starred: true) }

  scope :repo,     ->(repo_name)    { where(repository_full_name: repo_name) }
  scope :type,     ->(subject_type) { where(subject_type: subject_type) }
  scope :reason,   ->(reason)       { where(reason: reason) }
  scope :unread,   ->(unread)       { where(unread: unread) }
  scope :owner,    ->(owner_name)   { where(repository_owner_name: owner_name) }

  paginates_per 20

  class << self
    def attributes_from_api_response(api_response)
      attrs = DownloadService::API_ATTRIBUTE_MAP.map do |attr, path|
        [attr, api_response.to_h.dig(*path)]
      end.to_h
      if "RepositoryInvitation" == api_response.subject.type
        attrs[:subject_url] = "#{api_response.repository.html_url}/invitations"
      end
      attrs
    end
  end

  def mark_read(update_github: false)
    self[:unread] = false
    save(touch: false) if changed?

    if update_github
      user.github_client.mark_thread_as_read(github_id, read: true)
    end
  end

  def ignore_thread
    user.github_client.update_thread_subscription(github_id, ignored: true)
  end

  def mute
    mark_read(update_github: true)
    ignore_thread
  end

  def web_url
    subject_url.gsub("#{Octobox.config.github_api_prefix}/repos", Octobox.config.github_domain)
               .gsub('/pulls/', '/pull/')
               .gsub('/commits/', '/commit/')
               .gsub(/\/releases\/\d+/, '/releases/')
  end

  def repo_url
    "#{Octobox.config.github_domain}/#{repository_full_name}"
  end

  def unarchive_if_updated
    return unless self.archived?
    change = changes['updated_at']
    return unless change
    if self.archived && change[1] > change[0]
      self.archived = false
    end
  end

  def update_from_api_response(api_response, unarchive: false)
    attrs = Notification.attributes_from_api_response(api_response)
    self.attributes = attrs
    unarchive_if_updated if unarchive
    save(touch: false) if changed?
  end
end
