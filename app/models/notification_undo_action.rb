# frozen_string_literal: true

class NotificationUndoAction < ApplicationRecord
  EXPIRES_IN = 5.minutes
  ARCHIVE_BUFFER = 10.seconds
  ARCHIVE_DELAY = EXPIRES_IN + ARCHIVE_BUFFER

  has_secure_token :token

  belongs_to :user

  validates :action, presence: true
  validates :expires_at, presence: true
  validates :notification_states, presence: true

  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def self.record_archive!(user, notifications, archived: true)
    states = notifications.pluck(:id, :archived, :updated_at).map do |id, previously_archived, updated_at|
      {
        'id' => id,
        'archived' => previously_archived,
        'updated_at' => serialize_timestamp(updated_at)
      }
    end

    return if states.empty?

    # Archive actions stay until ArchiveWorker syncs them to GitHub, so a
    # missing record always means the user undid the action
    user.notification_undo_actions.expired.where.not(action: 'archive').delete_all

    user.notification_undo_actions.create!(
      action: archived ? 'archive' : 'unarchive',
      notification_states: states,
      expires_at: EXPIRES_IN.from_now
    )
  end

  def self.serialize_timestamp(time)
    time&.utc&.iso8601(6)
  end

  def notification_states
    JSON.parse(read_attribute(:notification_states) || '[]')
  end

  def notification_states=(states)
    write_attribute(:notification_states, JSON.generate(states))
  end

  def expired?
    expires_at <= Time.current
  end

  def archive_delay
    [expires_at - Time.current, 0].max + ARCHIVE_BUFFER
  end

  # Notifications that sync reopened, or that received new activity, since
  # this archive was recorded must not be archived on GitHub
  def github_ids_to_archive(github_ids)
    recorded_updated_at = notification_states.to_h { |state| [state['id'], state['updated_at']] }

    reopened_github_ids = user.notifications.where(id: recorded_updated_at.keys)
      .pluck(:id, :github_id, :archived, :updated_at)
      .reject { |id, _, archived, updated_at| archived && recorded_updated_at[id] == self.class.serialize_timestamp(updated_at) }
      .map(&:second)

    github_ids - reopened_github_ids
  end

  def restore!
    return false if expired?

    transaction do
      notification_states.group_by { |state| state['archived'] }.each do |archived, states|
        user.notifications.where(id: states.map { |state| state['id'] }).update_all(archived: archived)
      end

      destroy!
    end

    true
  end
end
