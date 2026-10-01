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
    states = notifications.pluck(:id, :archived).map do |id, archived|
      {
        'id' => id,
        'archived' => archived
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
